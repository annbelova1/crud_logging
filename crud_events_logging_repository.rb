require "elasticsearch"
require 'elasticsearch/persistence'
require 'elasticsearch/transport'

#repo for CRUDLogging service (./crud_logging.rb)
class CRUDEventsLoggingRepository
  include Elasticsearch::Persistence::Repository
  include Elasticsearch::Persistence::Repository::DSL

  LIMIT = 5000

  index_name 'crud_events_logging'
  client Elasticsearch::Client.new(host: "#{ENV['ELASTIC_HOST']}:#{ENV['ELASTIC_PORT']}", log: true)

  settings number_of_shards: 1

  # type: destroy, create, update
  def events_by_type(type, object_class)
    search(
        size: LIMIT.to_i, 
        query: {
          bool: { must: 
            [ { match: { name: type } }, 
              { match: { object_class: object_class } } ]
          }
        },
        sort: [ { timestamp: { order: "desc" } }] 
    )
  end

  def events_by_object(object)
    search(
        size: LIMIT.to_i, 
        query: {
          bool: { must: 
            [ { match: { object_id: object.id } },
              { match: { object_class: object.class.name } } ]
          }
        },
        sort: [ { timestamp: { order: "desc" } }] 
    )
  end
end
