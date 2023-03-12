
module Pod
    class Podfile
      class TargetDefinition
        def detect_prebuilt_pod(name, requirements)
          options = requirements.last || {}

          # prebuild
          @explicit_prebuild_pod_names ||= []
          @reject_prebuild_pod_names ||= []
          @explicit_prebuild_pod_names << Specification.root_name(name) if options.is_a?(Hash) && options[:binary]
          @reject_prebuild_pod_names << Specification.root_name(name) if options.is_a?(Hash) && options.include?(:binary) && !options[:binary]
          
          # header search path
          @explicit_header_search_pod_names ||= []
          @reject_header_search_pod_names ||= []
          @explicit_header_search_pod_names << Specification.root_name(name) if options.is_a?(Hash) && options[:framework_search_header]
          @reject_header_search_pod_names << Specification.root_name(name) if options.is_a?(Hash) && options.include?(:framework_search_header) && !options[:framework_search_header]

          options.delete(:binary) if options.is_a?(Hash)
          requirements.pop if options.empty?
        end
  
        # Returns the names of pod targets explicitly declared as prebuilt in Podfile using `:binary => true`.
        def explicit_prebuild_pod_names
          names = @explicit_prebuild_pod_names || []
          names += parent.explicit_prebuild_pod_names if !parent.nil? && parent.is_a?(TargetDefinition)
          names
        end

        def reject_prebuild_pod_names
          names = @reject_prebuild_pod_names || []
          names += parent.reject_prebuild_pod_names if !parent.nil? && parent.is_a?(TargetDefinition)
          names
        end

        def explicit_header_search_pod_names
          names = @explicit_header_search_pod_names || []
          names += parent.explicit_header_search_pod_names if !parent.nil? && parent.is_a?(TargetDefinition)
          names
        end

        def reject_header_search_pod_names
          names = @reject_header_search_pod_names || []
          names += parent.reject_header_search_pod_names if !parent.nil? && parent.is_a?(TargetDefinition)
          names
        end
  
        # ---- patch method ----
        # We want modify `store_pod` method, but it's hard to insert a line in the
        # implementation. So we patch a method called in `store_pod`.
        original_parse_inhibit_warnings = instance_method(:parse_inhibit_warnings)
        define_method(:parse_inhibit_warnings) do |name, requirements|
          detect_prebuilt_pod(name, requirements)
          original_parse_inhibit_warnings.bind(self).call(name, requirements)
        end
      end
    end
end

module Pod
    class Installer
      # Returns the names of pod targets detected as prebuilt, including
      # those declared in Podfile and their dependencies
      def prebuild_pod_names
        prebuilt_pod_targets.map(&:name).to_set
      end
  
      # Returns the pod targets detected as prebuilt, including
      # those declared in Podfile and their dependencies
      def prebuilt_pod_targets
        @prebuilt_pod_targets ||= begin
          explicit_prebuild_pod_names = aggregate_targets.flat_map { |target| 
            target.target_definition.explicit_prebuild_pod_names
          }.uniq

          reject_prebuild_pod_names = aggregate_targets.flat_map { |target| 
            target.target_definition.reject_prebuild_pod_names 
          }.uniq
          
          available_pod_names = []
          prebuild_sandbox = BinaryPrebuild::Sandbox.from_sandbox(self.sandbox)
          available_pod_names = prebuild_sandbox.target_paths.map {|path| path.basename.to_s } unless prebuild_sandbox.nil?
          if BinaryPrebuild.config.all_binary_enable?
            explicit_prebuild_pod_names = available_pod_names
          else
            explicit_prebuild_pod_names = (explicit_prebuild_pod_names & available_pod_names).uniq
          end
          explicit_prebuild_pod_names -= reject_prebuild_pod_names
          
          targets = pod_targets.select { |target| 
            explicit_prebuild_pod_names.include?(target.pod_name)
          }
          targets = targets.reject { |target| sandbox.local?(target.pod_name) } unless BinaryPrebuild.config.dev_pods_enabled?
          targets.map { |target| target.use_binary = true }
          targets
        end
      end
    end
end

module Pod
  class Target
    attr_accessor :use_binary

    def frame_header_search_paths_enable?
      return true if self.use_binary
      header_search_pod_names.include? self.name
    end

    def header_search_pod_names
      @explicit_header_search_pod_names ||= begin
        target_definitions.flat_map { |target_definition|
          target_definition.explicit_header_search_pod_names - target_definition.reject_header_search_pod_names
        }.uniq
      end
    end
  end
end