# lib/tasks/maintenance.rb
class TaskPrints
  def self.header(task_name)
    puts "*" * 60
    puts "Maintenance task #{task_name} started"
    puts "*" * 60
  end
end
namespace :maintenance do
  desc 'Search for tables with records older than X years'
  task :lookup_non_used_tables, [:years] => :environment do |t, args|
    years = args[:years].present? ? args[:years].to_i : 2
    tables_to_delete = []

    TaskPrints::header(t.name)

    ActiveRecord::Base.connection.tables.each do |table|
      # Check if the table corresponds to a model
      model = table.classify.safe_constantize
      next unless model

      # Check if the model has timestamps
      next unless model.column_names.include?('created_at') && model.column_names.include?('updated_at')

      # Check if the model has any records
      newest_record = model.where.not(updated_at: nil).order(updated_at: :desc).first
      if newest_record && newest_record.updated_at <= years.years.ago
        tables_to_delete << model
        puts "Table #{model.name} has #{model.count} records"
        puts "The newest record is from #{newest_record.updated_at} which is #{(Time.current - newest_record.updated_at).to_i / 1.day} days old"
        puts "=" * 50
      end
    end

    puts "Tables with no update records for the last #{years} years: #{tables_to_delete.map(&:name).join(', ')}"
  end
end
