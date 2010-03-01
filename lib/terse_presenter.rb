require "forwardable"

class TersePresenter < ActiveRecord::BaseWithoutTable
  extend Forwardable

  def self.presenter_for(klass, options={})
    # make accessors for model instance
    def_delegators variable_for(klass), *default_accessors(klass)
    # make the model instance accessable
    attr_accessor sym_for(klass)
    # make custom delegators
    add_extra_accessors(klass, options[:extra_accessors])
    add_extra_getters(klass, options[:extra_getters])
    add_extra_setters(klass, options[:extra_setters])
  end

  def initialize(params=nil)
    params.each_pair do |attribute, value|
      self.send "#{attribute}=", value
    end unless params.nil?
  end
  
  def copy_errors_to_presenter(activerecord_obj)
    copy_attrib_errors_to_presenter(activerecord_obj)
    copy_base_errors_to_presenter(activerecord_obj)
  end

  def copy_attrib_errors_to_presenter(activerecord_obj)
    activerecord_obj.errors.each do |attr,msg|
      if self.respond_to?(attr)
        self.errors.add(attr, msg)
      else
        self.errors.add_to_base("#{attr} #{msg}")
      end
    end
  end

  def copy_base_errors_to_presenter(activerecord_obj)
    self.errors.add_to_base( activerecord_obj.errors.on_base ) if activerecord_obj.errors.on_base
  end

  protected

  def self.add_extra_accessors(klass, accessor_array)
    return if accessor_array.blank? || !accessor_array.is_a?(Hash)
    extras = []
    accessor_array.each do |accr|
      extras << accessor_getter(accr)
      extras << accessor_setter(accr)
    end
    def_delegators variable_for(klass) *extras
  end

  def self.add_extra_setters(klass, setter_array)
    return if setter_array.blank? || setter_array.is_a?(Hash)
    extras = []
    setter_array.each do |accr|
      extras << accessor_setter(accr)
    end
    def_delegators variable_for(klass) *extras
  end

  def self.add_extra_getters(klass, getter_array)
    return if getter_array.blank? || getter_array.is_a?(Hash)
    extras = []
    getter_array.each do |accr|
      extras << accessor_setter(accr)
    end
    def_delegators variable_for(klass), *extras
  end

  def self.columns_for_default_accessors(klass)
    rejectables = ["id", "updated_at", "created_at"]
    columns_for(klass).select{|col| !rejectables.include?(col.name)}
  end

  def self.default_accessors(klass)
    accessors = []
    columns_for_default_accessors(klass).each do |col|
      accessors << accessor_getter(col.name)
      accessors << accessor_setter(col.name)
    end
    accessors
  end

  # MerchantEmployee => :@merchant_employee
  def self.variable_for(klass)
    "@#{klass.to_s.underscore}".intern
  end

  def self.sym_for(klass)
    klass.to_s.underscore.intern
  end

  def self.columns_for(klass)
    klass.columns
  end

  def self.accessor_setter(string)
    stringify(string).intern
  end

  def self.accessor_getter(string)
    "#{stringify(string)}=".intern
  end

  def self.stringify(obj)
    obj.to_s
  end

end

