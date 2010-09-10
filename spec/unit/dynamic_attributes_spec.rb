require File.expand_path("../../spec_helper", __FILE__)

module DynAttrSpecHelper
  def create_class(opts={})
    c = Class.new do
      include Friendly::Document
      use_dynamic_attributes opts
      attribute :name, String
    end
    c.table_name = opts[:table_name] if opts[:table_name]
    c
  end

  def create_tables_but_only_those_with_a_name
    Friendly::Document.documents = Friendly::Document.documents.reject {|a| a.name == ""}
    Friendly.create_tables!
  end
end

describe "document use_dynamic_attributes" do
  include DynAttrSpecHelper

  before do
    DynAttrDocument = create_class unless defined?(DynAttrDocument)
    create_tables_but_only_those_with_a_name
  end

  it "still allow saving a document" do
    obj = DynAttrDocument.new
    obj.name = "fubar"
    obj.save
  end

  it "should not allow dynamic assignment via missing_method" do
    obj = DynAttrDocument.new
    lambda { obj.fubar = "fubar" }.should raise_error(NoMethodError)
    lambda { obj.name = "fubar" }.should_not raise_error(NoMethodError)
  end
  
  it "creates new attributes via attributes=, use value as type and is case-sensitive" do
    DynAttrDocument.attributes.keys.should_not include(:fUbAr)
    obj = DynAttrDocument.new
    obj.attributes = { "fUbAr" => "snafu" }
    DynAttrDocument.attributes[:fUbAr].type.should equal(String)
  end
  
  it "save the new attribute and its value" do
    obj = DynAttrDocument.new
    obj.attributes = { "fubar" => "snafu" }
    obj.save
    obj = DynAttrDocument.find(obj.id)
    obj.fubar.should eql("snafu")
  end

  it "new attribute is persistent across all objects" do
    obj, obj2 = DynAttrDocument.new, DynAttrDocument.new
    obj.attributes = { "new_attribute" => "snafu" }
    obj2.new_attribute = "a value"
    obj2.save
    obj3 = DynAttrDocument.find(obj2.id)
    obj3.new_attribute.should eql("a value")
  end

  it "new attribute is not persistent across all classes" do
    klass1, klass2 = create_class, create_class
    klass1.new.attributes = { "new_attribute_number_two" => ""}
    klass1.attributes[:new_attribute_number_two].should_not eql(nil)
    klass2.attributes[:new_attribute_number_two].should eql(nil)
  end

  it "should create attributes on the fly if defined in DB" do
    obj = DynAttrDocument.new
    obj.attributes = { :why_not => 1 }
    obj.save
    klass = create_class(:table_name => "dyn_attr_documents")
    klass.attributes[:why_not].should eql(nil)
    klass.find(obj.id)
    klass.attributes[:why_not].should_not eql(nil)
    klass.attributes[:why_not].type.should eql(Fixnum)
  end

  it "should have a default value of nil" do
    obj = DynAttrDocument.new
    obj.attributes = { :banana => :apple }
    DynAttrDocument.attributes[:banana].default.should eql(nil)
    DynAttrDocument.attributes[:banana].type.should eql(Symbol)
  end
  
  it "have a default type if so desired = String has default value ''" do
    klass1 = create_class(:type => String)
    klass1.new.attributes = { 
      "a_number" => 1, "a_string" => "", 
      "a_float" => 2.3, "a_symbol" => :f 
    }
    ["number","string","float","symbol"].map { |a| "a_#{a}" }.each do |attrname|
      klass1.attributes[attrname.to_sym].type.should eql(String)
      klass1.attributes[attrname.to_sym].default.should eql("")
    end
  end

  it "have a default type if so desired - Integer" do
    klass1 = create_class(:type => Integer)
    klass1.new.attributes = { 
      "a_number" => 1, "a_string" => "", 
      "a_float" => 2.3, "a_symbol" => :f 
    }
    ["number","string","float","symbol"].map { |a| "a_#{a}" }.each do |attrname|
      klass1.attributes[attrname.to_sym].type.should eql(Integer)
      klass1.attributes[attrname.to_sym].default.should eql(nil)
    end
  end

  it "have a default value if so desired" do
    klass1 = create_class(:default => "defaultvalue")
    klass1.new.attributes = { 
      "a_number" => 1, "a_string" => "", 
      "a_float" => 2.3, "a_symbol" => :f 
    }
    ["number","string","float","symbol"].map { |a| "a_#{a}" }.each do |attrname|
      klass1.attributes[attrname.to_sym].default.should eql("defaultvalue")
    end
  end
end
