require './crud_events_logging_repository.rb'

class CRUDLogging
    # CRUDLogging.fire!({name: "update", type: "record", caller_id: current_user.id}) do 
    #   room.update(title: "room 42"); room 
    # end
    #
    #
    # or without block:
    # CRUDLogging.fire_object!(room, {name: "update", type: "record", caller_id: current_user.id}) 
    #
    # When you return or pass ActiveRecord object it will store object_class and object_id:
    #
    # POST http://elasticsearch:9200/crud_events_logging/_doc [status:201, request:0.013s, query:n/a]
    # > {"name":"update","object_class":"Room","object_id":4320, "timestamp":"2021-08-03T12:41:10+03:00","caller_id":11448}
    #
    # or you may pass no object finally:
    # CRUDLogging.fire!({name: "update", type: "record", caller_id: current_user.id}) 

    class LogWithoutName < StandardError; end;
  
    def self.fire!(attrs={})
      return if attrs.blank?
      block = proc { yield } if block_given?
      fire_object!(block.try(:call), attrs)
    end
  
    def self.fire_object!(object, attrs={})
      return if attrs.blank?
      begin
        new(object, attrs).call
      rescue => exception
        raise(exception)
      end  
    end
  
    attr_reader     :object, :attrs
    attr_accessor   :object_class, :object_id,  :timestamp
  
    def initialize(object, attrs)
      @object = object  
      @attrs  = attrs.with_indifferent_access
    end
  
    def call 
      raise LogWithoutName.new('Please provide name to attributes') unless attrs[:name]
      assign_attributes!
      CRUDEventsLoggingRepository.new.save(self)
    end
  
    def to_hash
      attrs.merge( internal_keys.inject({}){ |result, key| result.merge({key => self.send(key) })} )
    end
  
    private
  
    def assign_attributes!
      assign_model_attributes!
      set_timestamp!
      self
    end
  
    def assign_model_attributes!
      if object.present? && object.is_a?(ActiveRecord::Base)
        self.object_class = object.class.to_s
        self.object_id    = object.try(:id)
      end
    end
  
    def set_timestamp!
      self.timestamp = DateTime.current.to_s
    end
  
    def internal_keys
      %w(object_class object_id timestamp)
    end
  end
  