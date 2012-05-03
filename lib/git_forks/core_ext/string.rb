String.class_eval do
  # @param [module] module_ is my base module
  def to_class(module_ = Kernel)
    klass = self

    # in case +a+ module path is part of me already
    if (components = self.split('::')).size > 1
      components[0...-1].each {|c| module_ = module_.const_get(c) }
      klass = components.last
    end

    module_.const_get(klass)
  end
end
