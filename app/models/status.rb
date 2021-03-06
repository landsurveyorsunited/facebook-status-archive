class Status < ActiveRecord::Base
  attr_accessible :archive_id, :timestamp, :user_id, :message

	belongs_to :user
	belongs_to :archive
	validates_presence_of :message, :timestamp, :user_id, :archive_id
end
