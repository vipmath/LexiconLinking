
SEED_PROJECT = "step_names"
PROJECT_NAME = "story_steps"

require 'rubygems'
require 'active_record'


if ARGV.size < 1
  print "first argument should be password"
  return
end
print ARGV[0]

ActiveRecord::Base.establish_connection( 
:adapter => "mysql", 
:host => "sql.media.mit.edu",
:username => "litchfield",  
:password => ARGV[0],
:database => "todogo_game"
) 

class Steps < ActiveRecord::Base
end

# query to return steps, sorted by their task, based on constraints for variance.
stories = Steps.find_by_sql("
select b.task, b.avg, s2.* from tasks t2, steps s2, (
select task, id, count(*) as num, sum(num_steps)/count(*)  as avg,
pow(num_steps-(sum(num_steps)/(count(*))),2) as var_sq 
from
(select t.task, t.id, s.step, count(s.step) as num_steps from tasks t
inner join steps s on t.id = s.taskid
group by s.taskid) a
group by task
order by num desc, var_sq asc
limit 100) b 
where s2.taskid = t2.id
and t2.task = b.task
order by b.task, s2.id
")


last_task = ""
last_taskid = ""
f_out = nil #output file pointer
$sequence_replacements = {}

`rm -rf #{PROJECT_NAME}`  # shell command to clear stories directory
`mkdir #{PROJECT_NAME}`
`mkdir #{PROJECT_NAME}/seq`

if SEED_PROJECT.size > 0
    # load story keys from step_name extraction
    File.open("#{SEED_PROJECT}/#{SEED_PROJECT}.map", 'r').each_line do |l|
      k,vals = l.strip.split("    ")
      $sequence_replacements[k]=vals
    end
end


index_out = File.open("#{PROJECT_NAME}/#{PROJECT_NAME}.index",'w')
all_stories_out =  File.open("#{PROJECT_NAME}/#{PROJECT_NAME}.all",'w')

$story_steps = Hash.new(0)

# finds or adds id of item i in hash h
def hash_to_id(h,i)
	if h[i] == 0
		h[i] = h.size+1
	end
	h[i]
end

def replace_with_numbers(h,seq)
  if $sequence_replacements.has_key(seq)
    return $sequence_replacements[seq]
  else
    return seq.split(" ").collect {|x| hash_to_id(h,x)}.join(" ")
  end
end

ct = 0
for s in stories
	if last_task != s.task
		#print "==============\n#{s.task}\n==============\n"
		last_task = s.task
		last_taskid = s.taskid
    dir = "#{PROJECT_NAME}/seq/#{s.task.gsub(" ","_")}"
    `mkdir #{dir}`
    f_out = File.open(dir+"/#{ct}",'w')
	end
	if s.taskid != last_taskid
		last_taskid = s.taskid
    f_out.close()
    ct += 1
		#f_out.puts "# #{s.avg}"
    f_out = File.open(dir+"/#{ct}",'w')
    index_out.puts "#{dir}/#{ct}"

	end
  all_stories_out.puts s.step
	f_out.puts "#{replace_with_numbers($story_steps,s.step)}" 
end

k_out = File.open("#{PROJECT_NAME}/#{PROJECT_NAME}.keys",'w')
$story_steps.each {|k,v| k_out.puts "#{v}\t#{k}"}



