module PMID
  def self.make_get_request(url)
    uri = URI(url)
    res = Net::HTTP.get_response(uri)
    # STDERR.puts "Res is #{res.inspect}"
    raise StandardError.new(res.body) unless res.code == '200'
    res.body
  end
  def self.call_pubmed_api(pubmed_id)
    # STDERR.puts "URL is #{PMID.url_for_pubmed_id(pubmed_id).inspect}"
    http_resp = PMID.make_get_request(PMID.url_for_pubmed_id(pubmed_id))
    PubMedResponse.new(http_resp, pubmed_id.to_s)
  end
  def self.get_citation_from_pubmed_id(pubmed_id)
    resp = PMID.call_pubmed_api(pubmed_id)
    #TODO: make this less hacky
    resp.citation unless resp.error == 'cannot get document summary'
  end

  def self.pubmed_url(pubmed_id)
    "https://www.ncbi.nlm.nih.gov/pubmed/#{pubmed_id}"
  end

  private
  def self.url_for_pubmed_id(pubmed_id)
    "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=pubmed&id=#{pubmed_id}&retmode=json&tool=DGIdb&email=help@dgidb.org"
  end

  class PubMedResponse
    attr_reader :result
    def initialize(response_body, pmid)
      # STDERR.puts "Response body is #{response_body.inspect}"
      @result = JSON.parse(response_body)['result'][pmid]
    end

    def error
      result['error']
    end

    def citation
      [first_author, year, article_title, journal].compact.join(', ')
    end

    def authors
      result['authors'].map{|a| a['name']}
    end

    def pmc_id
      result['articleids'].each do |articles|
        if articles['idtype'] == 'pmcid'
          return articles['value']
        end
      end
      return
    end

    def first_author
      if authors.size > 1
        authors.first + " et al."
      else
        authors.first
      end
    end

    def publication_date
      result['pubdate']
    end

    def year
      Date.parse(result['sortpubdate']).year
    end

    def journal
      result['source']
    end

    def full_journal_title
      result['fulljournalname']
    end

    def article_title
      result['title']
    end
  end
end
