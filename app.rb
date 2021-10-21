require 'rubygems'
require 'bundler'

Bundler.require(:default)

require 'sinatra'
require 'sinatra/reloader'
require './crud_logging.rb'
require './crud_events_logging_repository.rb'

set :database, {adapter: "sqlite3", database: "db/foo.sqlite3"}



ActiveRecord::Migration.create_table :models, if_not_exists: true do |t|
  t.string :title
  t.string :color
  t.integer :count, default: 0

  t.timestamps
end


before do
    params = [
        { title: '1', color: 'white' },
        { title: '2', color: 'blue' },
        { title: '3', color: 'red' }
    ] 

    params.each { |p| Model.find_or_create_by(p.merge(count: rand(8))) }
  
end

get '/models' do
    Model.all.to_json
end

post '/models' do
    model = Model.new(params)
    if model.save
        CRUDLogging.fire_object!(model, {name: "create", type: "record", attributes: model.as_json})
        model.to_json
    else
        model.errors.messages.to_json
    end 
end

put '/model/:id' do 
    model = Model.find_by_id(params[:id])

    halt 403 if model.nil? 

    if model.update(params.except(:id))
        CRUDLogging.fire_object!(model, {name: "update", type: "record", attributes: model.as_json})

        [201, model.to_json]
    else
        [500, { message: "Failed to update model" }.to_json]
    end 
end

delete '/model/:id' do |id|
    model = Model.find_by_id(params[:id])

    if model
      model.destroy

      CRUDLogging.fire_object!(model, {name: "destroy", type: "record", attributes: model.as_json})

      status 204
    else
      status 500
    end
end