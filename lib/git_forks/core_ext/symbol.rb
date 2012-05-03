Symbol.class_eval do
  def to_class(module_ = Kernel)
    module_.const_get(self)
  end
end
