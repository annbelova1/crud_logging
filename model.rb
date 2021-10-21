require 'sinatra/activerecord'

class Model < ActiveRecord::Base
    validates :title, presence: true

end