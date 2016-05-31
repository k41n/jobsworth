require 'rubygems'
require 'active_record'
require 'active_support'
require 'action_view'
require 'erb'
require 'yaml'
require 'activerecord-jdbcmysql-adapter'

config = YAML.load(ERB.new(File.new('config/database.yml').read).result(binding))[ENV['RAILS_ENV']]
ActiveRecord::Base.establish_connection(config)

class AbstractTask < ActiveRecord::Base
  self.table_name = 'tasks'
  has_many      :owners, through: :task_owners, source: :user
  has_many      :task_owners, dependent: :destroy, foreign_key: 'task_id'
  has_many      :work_logs, -> { order('started_at asc') }, dependent: :destroy, foreign_key: 'task_id'

  COMPANY_ID =1
  LAST_WEEK = Date.today..Date.today - 1.week
  REPORT_STATUSES = {0 => :open, 1 => :closed, 2 => :high, 3 => :invalid, 4 => :duplicate}
  REPORT_PRIORITY = {0 => :critical, 1 => :urgent, 2 => :high, 3 => :normal, 4 => :low, 5 => :lowest}

  scope :opened, -> { where('status = ? AND company_id = ?', REPORT_STATUSES.key(:open), COMPANY_ID) }
  scope :closed, -> { where('status = ? AND company_id = ?', REPORT_STATUSES.key(:closed), COMPANY_ID) }
  scope :other, -> { where(company_id: COMPANY_ID).where.not(created_at: LAST_WEEK).where.not(completed_at: LAST_WEEK) }
end

class TaskRecord < AbstractTask
end

class TaskUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :task, class_name: 'AbstractTask'
end

class TaskOwner < TaskUser
end

class User < ActiveRecord::Base
  has_many      :tasks, through: :task_owners, class_name: 'TaskRecord'
  has_many      :task_owners, dependent: :destroy
  has_many      :work_logs
end

class WorkLog < ActiveRecord::Base
  belongs_to :task, class_name: 'AbstractTask', foreign_key: 'task_id'
  belongs_to :user, class_name: 'User', foreign_key: 'user_id'
end

erb = ERB.new(File.open("#{__dir__}/tasks.html.erb").read)
print erb.result binding

