class FilterChain
  def initialize
    @all_include = []
    @all_exclude = []
  end

  #TODO it will now recalculate if you modify the filter after calcuating it
  #but once something is excluded, it can't be added back in
  #is that an acceptable limitation?
  Filter.all_filters.each do |filter|
    ['include', 'exclude'].each do |filter_type|
      define_method "#{filter_type}_#{filter}" do |*filter_criteria|
        instance_variable_get("@all_#{filter_type}") << filter.classify.constantize.new(*filter_criteria)
        instance_variable_set("@computed_#{filter_type}", nil)
        instance_variable_set("@computed_final", nil)
        self
      end
    end
  end

  def include?(id)
    evaluate_all_filters.include?(id)
  end

  private
  def evaluate_all_filters
    @computed_include ||= evaluate_filter(@all_include)
    @computed_exclude ||= evaluate_filter(@all_exclude)
    @computed_final ||= @computed_include - @computed_exclude
  end

  def evaluate_filter(filter)
    computed = nil
    filter.group_by(&:axis).each do |_, value|
      if computed
        computed = computed & evaluate_axis(value)
      else
        computed = evaluate_axis(value)
      end
    end
    if computed
      store(computed, composite_key(filter))
    else
      Set.new
    end
  end

  def composite_key(filters)
    filters.sort_by { |filter| filter.cache_key }
      .map { |filter| filter.cache_key }
      .join('.')
  end

  def evaluate_axis(filters)
    key = composite_key(filters)
    if Rails.cache.exist?(key)
      Rails.cache.fetch(key)
    else
      current_filter = filters.pop
      if filters.empty?
        store(current_filter.resolve, key)
      else
        results = evaluate_axis(filters)
        store(results + current_filter.resolve, key)
      end
    end
  end

  def store(filter, key)
    Rails.cache.write(key, filter)
    filter
  end
end
