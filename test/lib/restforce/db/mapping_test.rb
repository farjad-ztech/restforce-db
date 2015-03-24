require_relative "../../../test_helper"

describe Restforce::DB::Mapping do

  configure!

  let(:mapping) { Restforce::DB::Mapping.new(mappings) }
  let(:mappings) do
    {
      column_one: "SF_Field_One__c",
      column_two: "SF_Field_Two__c",
    }
  end

  describe "#initialize" do

    it "assigns the passed mappings to the object" do
      expect(mapping.mappings).to_equal(mappings)
    end
  end

  describe "#add_mappings" do
    let(:new_mappings) { { a: "few", more: "mappings" } }

    before do
      mapping.add_mappings new_mappings
    end

    it "appends the passed mappings to the object's internal collection" do
      expect(mapping.mappings).to_equal(mappings.merge(new_mappings))
    end
  end

  describe "#attributes" do

    it "builds a normalized Hash of database attribute values" do
      attributes = mapping.attributes(:database) do |attribute|
        expect(mapping.database_fields.include?(attribute)).to_equal true
        attribute
      end

      expect(attributes.keys).to_equal(mapping.database_fields)
      expect(attributes.values).to_equal(mapping.database_fields)
    end

    it "builds a normalized Hash of Salesforce field values" do
      attributes = mapping.attributes(:salesforce) do |attribute|
        expect(mapping.salesforce_fields.include?(attribute)).to_equal true
        attribute
      end

      expect(attributes.keys).to_equal(mapping.database_fields)
      expect(attributes.values).to_equal(mapping.salesforce_fields)
    end
  end

  describe "#convert" do
    let(:attributes) { { column_one: "some value" } }

    it "converts an attribute Hash to a Salesforce-compatible form" do
      expect(mapping.convert(:salesforce, attributes)).to_equal(
        mappings[attributes.keys.first] => attributes.values.first,
      )
    end

    it "performs no special conversion for database columns" do
      expect(mapping.convert(:database, attributes)).to_equal(attributes)
    end
  end
end