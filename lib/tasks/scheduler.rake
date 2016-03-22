desc "This task is called by the Heroku scheduler add-on"
task :reset_applicable_monthly_upload_limits => :environment do
  puts "Resets monthly upload limits for users who are beginning a new cycle (which is monthly)"
  UserMetaDatum.reset_applicable_cycles
  puts "done."
end
