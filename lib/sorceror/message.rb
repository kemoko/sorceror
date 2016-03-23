class Sorceror::Message
  attr_accessor :payload

  def initialize(options)
    @payload        = options.fetch(:payload)
    @topic          = options.fetch(:topic, nil)
    @partition_with = options.fetch(:partition_with, nil)
  end

  def parsed_payload
    @parsed_payload ||= if payload.is_a?(Hash)
      payload.with_indifferent_access
    else
      MultiJson.load(payload).with_indifferent_access
    end
  end

  def to_s
    @to_s ||= MultiJson.dump(parsed_payload)
  end

  def type
    parsed_payload['type']
  end

  def hash
    raise NotImplementedError
  end

  def partition_key
    raise "parition_with not set" unless @partition_with

    "#{parsed_payload[:type]}/#{@partition_with}"
  end

  def topic
    raise "topic not set" unless @topic
    @topic
  end

  def key
    raise NotImplementedError
  end

  class OperationBatch < self
    def id
      parsed_payload['id']
    end

    def attributes
      parsed_payload['attributes']
    end

    def operations
      parsed_payload['operations'].map { |op| Operation.new(self, op) }
    end

    def model
      Sorceror::Model.models[self.type]
    end

    def hash
      operations.collect(&:hash).hash
    end

    def key
      partition_key
    end

    class Operation
      def initialize(batch, payload)
        @batch = batch
        @payload = payload
      end

      def name
        @payload['name'].to_sym
      end

      def attributes
        @payload['attributes']
      end

      def create?
        self.name == :create
      end

      def proc
        @batch.model.operations[self.name][:proc]
      end

      def event
        @batch.model.operations[self.name][:event]
      end

      def hash
        if name == :create
          attributes['id']
        else
          @payload.hash
        end
      end
    end
  end

  class Event < self
    def id
      parsed_payload[:id]
    end

    def attributes
      parsed_payload[:attributes]
    end

    def name
      parsed_payload[:name].to_sym
    end

    def at
      parsed_payload[:at]
    end

    def key
      "#{partition_key}/#{parsed_payload[:name]}/#{parsed_payload.hash}"
    end
  end

  class Snapshot < self
    def id
      parsed_payload[:id]
    end

    def attributes
      parsed_payload[:attributes]
    end

    def key
      partition_key
    end
  end
end
