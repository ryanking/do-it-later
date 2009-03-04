class DoItLater::Worker
  def initialize
    @logger = RAILS_DEFAULT_LOGGER
  end

  def get_job
    (1..5).each do |p|
      if j = STARLING.fetch("work_#{p}")
        return JSON.parse(j).symbolize_keys
      end
    end
  end

  def run_job job
    job[:class].constantize.find(job[:id]).send(job[:method])
  end

  def run
    while($running)
      if job = get_job
        begin
          @logger.info "working on #{job[:class]}[#{job[:id]}].#{job[:method]}"
          run_job(job)
        rescue ActiveRecord::StatementInvalid
          if e.message.include? "MySQL server has gone away"
            ActiveRecord::Base.verify_active_connections!
          else
            raise e
          end
        rescue Interrupt
          raise e
        rescue Exception => e
          if Rails.env == 'production'
            MyExceptionNotifier.deliver_exception_notification(e, {:job => job.inspect})
            STARLING.set("work_5", j)
          else
            raise e
          end
        end
      else
        sleep 0.1
      end
    end
  end
end
