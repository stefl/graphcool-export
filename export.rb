require "http"
require "json"
require "thor"

class GraphcoolExport < Thor

  desc "hidden", :hide => true
  def setup_folder_structure export_name
    export_path = "exports/#{export_name}"
    data_path = "#{export_path}/data"

    export_dir = Dir.mkdir(export_path) unless Dir.exist?(export_path)
    data_dir = Dir.mkdir(data_path) unless Dir.exist?(data_path)

    cursor_file_name = "cursor.json"
    cursor_path = "#{export_path}/#{cursor_file_name}"
    if !File.exist?(cursor_path)
      starting_json = {
        "fileType": "nodes",
        "cursor": {
          "table": 0,
          "row": 0,
          "field": 0,
          "array": 0
        }
      }

      File.open(cursor_path, "w") do |f|
        f.write starting_json.to_json
      end
    end
    return cursor_path, data_path
  end

  desc "hidden", :hide => true
  def choose_export_name path
    export_name = path.split("/").last
    if(export_name.strip.empty?)
      export_name = project_id
    end
    export_name
  end

  desc "--token \"your_graphcool.token\" --project graphcool_project_id ", "Export a project to JSON files"
  option :token, :type => :string, :required => true
  option :project, :type => :string, :required => true
  option :path, :type => :string

  def export
    path = options[:path] || options[:project]
    project_id = options[:project]
    token = options[:token]

    export_name = choose_export_name path

    cursor_path, data_path = setup_folder_structure(export_name)

    perform cursor_path, data_path, token, project_id
  end

  desc "hidden", :hide => true
  def perform cursor_path, data_path, token, project_id
    completed = false
    count_max = 0
    count = 1
    failure_time = nil
    max_failure_time = 60000
    while((!completed) && (count_max == 0 || (count < count_max))) do
      cursor = JSON.parse(File.read(cursor_path))
      puts "Call API with #{cursor.to_json}"
      response = HTTP.auth("Bearer #{token}").post(
        "https://api.graph.cool/simple/v1/#{project_id}/export", 
        :json => cursor
      )
      if response.code == 200
        json = JSON.parse(response.body)
        if(json['error']) 
          puts json['error']
          puts "--"
          puts json
          completed = true
        else
          time = Time.now.to_i
          puts "Got result: #{time}"
          File.open("#{data_path}/result-#{time}.json", "w") do |f|
            f.write response.body
          end
          if(json['cursor'])
            new_cursor = {
                "fileType": "nodes",
                "cursor": json['cursor']
              }.to_json
            puts "Write new cursor: #{new_cursor.to_json}"
            File.open(cursor_path, "w") do |f|
              f.write(new_cursor)
            end
            if(
              (json['cursor']['table'].to_i == -1) &&
              (json['cursor']['row'].to_i == -1) &&
              (json['cursor']['field'].to_i == -1) &&
              (json['cursor']['array'].to_i == -1)
            )
              puts "Export complete!"
              completed = true
            end
          end
        end
        count += 1
      else
        puts "Error: #{response.code}"
        puts ""
        puts response.body
        failure_time = failure_time || Time.now 
        if(Time.now - failure_time < max_failure_time)
          sleep 1
        else
          puts "Timed out"
          completed = true
        end
      end
    end
  end
end

GraphcoolExport.start(ARGV)
