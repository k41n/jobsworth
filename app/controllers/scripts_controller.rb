# encoding: UTF-8

require 'open3'
require 'pathname'

class ScriptsController < ApplicationController
  before_filter :authorize_user_is_admin

  def index
    Dir.chdir(Rails.root) do |root|
      bash = `which bash`.strip
      if defined?($servlet_context)
        ruby = "script/jruby_jar_exec"
      else
        ruby = "ruby"
      end
      runner = "script/rails runner -e development"
      script = "#{Setting.custom_scripts_root}/#{ params[:script] }".inspect

      cmd = "#{ruby} #{script}"

      Rails.logger.info cmd
      result = ""
      Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thread|
        result += stdout.read
        errors = stderr.read
        if !errors.blank?
          result += "\n#{ errors }"
        end
      end

      response.content_type = "text/html"
      render :text => result
    end
  end
end
