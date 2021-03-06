module Polywag
  module ControllerAdditions
    def find_and_authorize_nester(nesters)
      nester = find_nester(nesters)
      authorize! :nested_actions, nester if nester
      nester
    end

    def build_member(nester, resource_params)
      resource_base(nester).new(resource_params)
    end

    def build_and_authorize_member(nester, resource_params=nil)
      member = build_member(nester, resource_params)
      authorize! current_action, member
      member
    end

    def load_and_authorize_member(nester, resource_params=nil)
      member = load_authorized_collection(nester).find(member_id)
      member.assign_attributes resource_params if resource_params
      authorize! current_action, member
    end

    def load_authorized_collection(nester)
      resource_base(nester).accessible_by(current_ability)
    end

    # The object that methods (such as "find", "new" or "build") are called on.
    def resource_base(nester)
      if nester
        nester.send(controller_name)
      else
        controller_name.classify.constantize
      end
    end

    def load_resource_base(nesters)
      resource_base(find_nester(nesters))
    end

    def member_id
      polywag_path_parameters[:id]
    end

    def nester_id(nester_name)
      polywag_path_parameters["#{nester_name.to_s.underscore}_id"]
    end

    def current_action
      polywag_path_parameters[:action]
    end

    def find_nester(nesters)
      nesters.each do |nester_name|
        param = nester_id(nester_name)
        if param
          nester = nester_name.to_s.classify.constantize.find(param)
          return nester
        end
      end
      nil
    end

    def unnest(member, nester)
      if member && nester
        member.send("#{nester.class.name.underscore}=", nil)
      end
    end

    def polywag_path_parameters
      # this separate method allows easier overriding
      request.path_parameters.with_indifferent_access
    end
  end
end

if defined? ActionController::Base
  ActionController::Base.class_eval do
    include Polywag::ControllerAdditions
  end
end
