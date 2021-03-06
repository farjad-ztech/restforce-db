require_relative "../../../test_helper"

describe Restforce::DB::Collector do

  configure!
  mappings!

  let(:collector) { Restforce::DB::Collector.new(mapping) }

  describe "#run", vcr: { match_requests_on: [:method, VCR.request_matchers.uri_without_param(:q)] } do
    let(:attributes) do
      {
        "Name"             => "Custom object",
        "Example_Field__c" => "Some sample text",
      }
    end
    let(:salesforce_id) { Salesforce.create!(salesforce_model, attributes) }
    let(:key) { [salesforce_id, salesforce_model] }

    subject { collector.run }

    describe "given an existing Salesforce record" do
      before { salesforce_id }

      describe "which has not been synchronized" do

        it "does not store any attributes" do
          expect(subject[key]).to_be :empty?
        end
      end

      describe "which has been synchronized" do
        let(:database_metadata) { { salesforce_id: salesforce_id, synchronized_at: Time.now + 1 } }
        let(:database_record) do
          database_attributes = mapping.convert(database_model, attributes)
          database_model.create!(database_attributes.merge(database_metadata))
        end

        before { database_record }

        it "returns the attributes from the Salesforce record" do
          record = mapping.salesforce_record_type.find(salesforce_id)

          expect(subject[key]).to_equal(
            record.last_update => {
              "Name" => attributes["Name"],
              "Example_Field__c" => attributes["Example_Field__c"],
            },
          )
        end
      end
    end

    describe "given an existing database record" do
      let(:salesforce_id) { "a001a000001E1vREAL" }
      let(:database_metadata) { { salesforce_id: salesforce_id, synchronized_at: Time.now } }
      let(:database_record) do
        database_attributes = mapping.convert(database_model, attributes)
        database_model.create!(database_attributes.merge(database_metadata))
      end

      before { database_record }

      it "returns the attributes from the database record" do
        record = mapping.database_record_type.find(salesforce_id)

        expect(subject[key]).to_equal(
          record.last_update => {
            "Name" => attributes["Name"],
            "Example_Field__c" => attributes["Example_Field__c"],
          },
        )
      end
    end

    describe "given a Salesforce record with an associated database record" do
      let(:database_attributes) do
        {
          name:    "Some existing name",
          example: "Some existing sample text",
        }
      end
      let(:database_metadata) { { salesforce_id: salesforce_id, synchronized_at: Time.now } }
      let(:database_record) { database_model.create!(database_attributes.merge(database_metadata)) }

      before { database_record }

      it "returns the attributes from both records" do
        sf_record = mapping.salesforce_record_type.find(salesforce_id)
        db_record = mapping.database_record_type.find(salesforce_id)

        expect(subject[key]).to_equal(
          sf_record.last_update => {
            "Name" => attributes["Name"],
            "Example_Field__c" => attributes["Example_Field__c"],
          },
          db_record.last_update => {
            "Name" => database_attributes[:name],
            "Example_Field__c" => database_attributes[:example],
          },
        )
      end
    end

    describe "when the record has not been updated outside of the system" do
      subject do
        Restforce::DB::Runner.stub_any_instance(:changed?, false) do
          collector.run
        end
      end

      before { salesforce_id }

      it "does not collect any changes" do
        expect(subject[key]).to_be :empty?
      end
    end

  end
end
