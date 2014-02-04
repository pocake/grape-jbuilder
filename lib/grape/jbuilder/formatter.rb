module Grape
  module Formatter
    module Jbuilder
      class << self

        attr_reader :env
        attr_reader :endpoint

        def call(object, env)
          @env      = env
          @endpoint = env['api.endpoint']

          if jbuilderable?
            jbuilder do |template|
              if layout = env['api.tilt.layout']
                if endpoint.instance_variable_get(:@error).blank?
                  engine = ::Tilt.new(view_path(template), nil, view_path: env['api.tilt.root'])
                  json   = engine.render(endpoint, {})
                  endpoint.instance_variable_set :@data, JSON.parse(json) # TODO embed directory
                end
                engine = Tilt::JbuilderTemplate.new(File.open(layout))
                json = engine.render(endpoint, {})
              else
                engine = ::Tilt.new(view_path(template), nil, view_path: env['api.tilt.root'])
                json = engine.render(endpoint, {})
              end
              json
            end
          else
            Grape::Formatter::Json.call object, env
          end
        end

        private

        def view_path(template)
          if template.split('.')[-1] == 'jbuilder'
            File.join(env['api.tilt.root'], template)
          else
            File.join(env['api.tilt.root'], (template + '.jbuilder'))
          end
        end

        def jbuilderable?
          !! endpoint.options[:route_options][:jbuilder]
        end

        def jbuilder
          template = endpoint.options[:route_options][:jbuilder]
          raise 'missing jbuilder template' unless template
          set_view_root unless env['api.tilt.root']
          yield template
        end

        def set_view_root
          raise "Use Rack::Config to set 'api.tilt.root' in config.ru"
        end
      end
    end
  end
end
