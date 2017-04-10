class DrugPresenter < SimpleDelegator
  def initialize(drug)
    @drug = drug
    super
  end

  def source_db_names
    @uniq_db_names ||= DataModel::Source.source_names_with_drug_claims
  end

  def grouped_names
    @grouped_names ||= group_map(@drug)
  end

  def group_map(drug)
    hash = drug_claims.each_with_object({}) do |drug_claim, h|
      source_db_name = drug_claim.source.source_db_name
      names = drug_claim.drug_claim_aliases.map{|a| a.alias} << drug_claim.name
      names.each do |name|
        h[name] ||= Hash.new {|key, val| false}
        h[name][source_db_name] = true
      end
    end

    [].tap do |results|
      hash.each_pair do |key, value|
        results << GeneNamePresenter.new(key, value, source_db_names)
      end
    end
  end

  def sorted_claims
    drug_claims.sort_by{ |d| [(d.drug_claim_attributes.empty? ? 1 : 0), (d.drug_claim_aliases.empty? ? 1 : 0), -d.drug_claim_attributes.length, d.sort_value] }
  end

- aliases = gene.gene_claims.map{|claim| claim.gene_claim_aliases}.flatten
- gene_claim_attrs = gene.gene_claims.map{|claim| claim.gene_claim_attributes}.flatten
- interaction_claims = gene.interactions.map{|interaction| interaction.interaction_claims}.flatten
- interaction_claim_attrs = interaction_claims.map{|claim| claim.interaction_claim_attributes}.flatten
- all_attrs = gene_claim_attrs | interaction_claim_attrs
- info = all_attrs.reject{|attribute| attribute.name == 'PMID'}
- publications = all_attrs.select{|attribute| attribute.name == 'PMID'}.map{|pub| pub.value}

  def info # non pmid info
    drug.drug_attributes
    .reject{|attribute| attribute.name == 'PMID'}
  end 

  def pubs # publication model objects
    drug.drug_attributes
    .select{|attribute| attribute.name == 'PMID'}
    .map{|pub| DataModel::Publication.find(pub.value)}
  end

end
