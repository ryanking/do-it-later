module DoItLater
  module InstanceMethods
    def later method, priority=3
      raise ArgumentError unless (1..5).include?(priority)
      raise "you may not call #later on an unsaved model" if new_record?
      STARLING.set "work_#{priority}", {:id => id, :class => self.class.to_s, :method => method}.to_json
    end
  end
end