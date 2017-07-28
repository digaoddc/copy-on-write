require 'logger'

main_pid = $$
logger = Logger.new $stdout
logger.formatter = proc do |severity, datetime, progname, msg|
  name = $$ == main_pid ? 'MAIN' : $$
  "#{datetime}: [#{name}] #{msg}\n"
end

memory = proc do
  memory_usage_mb = `ps -o rss -p #{$$}`.chomp.split("\n").last.to_i / 1024
  logger.info "Memory usage is #{memory_usage_mb} MB"
  memory_usage_mb
end

array = []

experiment = proc do |&blk|
  initial_memory = memory.call
  blk.call
  final = memory.call - initial_memory
  logger.info "Memory increase by #{final} MB!!"
  logger.info "----End of experiment\n\n"
end

experiment.call do
  (1..5_000_000).each { |e| array << e}
end


fork do
  experiment.call do
  logger.info "I won\'t mess up with shared memory"
  end
end

Process.wait

fork do
  experiment.call do
    danger = array.each {|e| e }
  end
end


Process.wait

fork do
  experiment.call do
    danger = array.map {|e| e }
  end
end


Process.wait