require "test_helper"

class DevisExtractorServiceTest < ActiveSupport::TestCase
  test "extract parses the structured JSON response and drops variant lines" do
    payload = {
      items: [
        { reference: "REF-1", designation: "Article retenu", quantity: 2, unit: "PCE", unit_price: 10.0, is_variant: false },
        { reference: "REF-2", designation: "Article variante", quantity: 1, unit: "PCE", unit_price: nil, is_variant: true }
      ],
      surcharges: [
        { label: "Supplément carburant", amount: 5.04 }
      ]
    }.to_json

    service = DevisExtractorService.new("%PDF-fake".b, "HGC")
    service.instance_variable_set(:@client, fake_client(payload))

    with_api_key do
      result = service.extract
      assert_equal 1, result[:items].length
      assert_equal "REF-1", result[:items].first[:reference]
      assert_equal 1, result[:surcharges].length
      assert_equal "Supplément carburant", result[:surcharges].first[:label]
      assert_equal 5.04, result[:surcharges].first[:amount]
    end
  end

  test "extract raises a French error when the API key is missing" do
    service = DevisExtractorService.new("%PDF-fake".b, "HGC")
    original = ENV.delete("ANTHROPIC_API_KEY")
    error = assert_raises(DevisExtractorService::ExtractionError) { service.extract }
    assert_match(/ANTHROPIC_API_KEY/, error.message)
  ensure
    ENV["ANTHROPIC_API_KEY"] = original if original
  end

  test "extract raises a French error on unparsable JSON" do
    service = DevisExtractorService.new("%PDF-fake".b, "HGC")
    service.instance_variable_set(:@client, fake_client("not json"))

    with_api_key do
      assert_raises(DevisExtractorService::ExtractionError) { service.extract }
    end
  end

  private

  def with_api_key
    original = ENV["ANTHROPIC_API_KEY"]
    ENV["ANTHROPIC_API_KEY"] = "test-key"
    yield
  ensure
    ENV["ANTHROPIC_API_KEY"] = original
  end

  def fake_client(response_text)
    text_block = Struct.new(:type, :text).new(:text, response_text)
    fake_response = Struct.new(:content).new([ text_block ])
    fake_messages = Object.new
    fake_messages.define_singleton_method(:create) { |*_args, **_kwargs| fake_response }
    fake_client = Object.new
    fake_client.define_singleton_method(:messages) { fake_messages }
    fake_client
  end
end
