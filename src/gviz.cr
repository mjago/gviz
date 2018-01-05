require "./gviz/*"
require "graphviz"
require "kemal"

module Gviz
  class Visualizer
    FONT = "Helvetica-Bold"

    property data : Data

    struct InOut
      property name : String
      property size : Int32
      property values : Array(Float64)

      def initialize(@name = "",
                     @size = 0,
                     @values = Array(Float64).new)
      end
    end

    struct Hidden
      property count : Int32
      property sizes : Array(Int32)
      property values : Array(Array(Float64))

      def initialize(@count = 0,
                     @sizes = Array(Int32).new,
                     @values = Array(Array(Float64)).new)
      end
    end

    struct Mapping
      property input : Array(Int32)
      property output : Array(Int32)
      property hidden : Array(Array(Int32))

      def initialize(@input = Array(Int32).new,
                     @output = Array(Int32).new,
                     @hidden = Array(Array(Int32)).new)
      end
    end

    struct Data
      property input : InOut
      property hidden : Hidden
      property output : InOut
      property mapping : Mapping

      def initialize(@input = InOut.new,
                     @output = InOut.new,
                     @hidden = Hidden.new,
                     @mapping = Mapping.new)
      end
    end

    def initialize(title = "graph")
      @title = title
      @data = Data.new
      @graph = GraphViz.new(:G, type: :digraph)
      @nodes = Array(GraphViz::Node).new
      @mapping = Array(Array(Int32)).new
    end

    def input=(val : NamedTuple(name: String, size: Int32))
      self.input = {name: val[:name], size: val[:size], values: Array(Float64).new}
    end

    def input=(val)
      @data.input = InOut.new(val[:name], val[:size], val[:values])
    end

    def hidden=(val)
      @data.hidden = Hidden.new(val[:count], val[:sizes], val[:values])
    end

    def output=(val : NamedTuple(name: String, size: Int32))
      self.output = {name: val[:name], size: val[:size], values: Array(Float64).new}
    end

    def output=(val)
      @data.output = InOut.new(val[:name], val[:size], val[:values])
    end

    def build_label(values, idx)
      return "#{idx + 1}" if values.empty?
      sprintf("%0.2f", values[idx])
    end

    def build_input
      @graph.add_subgraph(@data.input.name, GraphViz.new("cluster_1", type: :subgraph)) do |inp|
        inp[:label] = "#{@data.input.name}"
        inp[:labelloc] = "top"
        inp[:labeljust] = "center"
        inp[:style] = "filled"
        inp[:fillcolor] = "lightgreen:green"
        inp[:gradientangle] = 270
        inp[:fontname] = FONT
        inp[:fontsize] = 20
        input_size = @data.input.size
        input_size.times do |x|
          val_s = build_label(@data.input.values, @data.mapping.input[x])
          @nodes << inp.add_node(x.to_s, label: val_s, style: "filled",
            color: "midnightblue", fillcolor: "orange:firebrick", fontname: FONT)
          puts
          puts
        end
      end
    end

    def build_hidden
      @graph.add_subgraph("hide", GraphViz.new("cluster_2", type: :subgraph)) do |hide|
        hide[:label] = ""
        hide[:style] = "radial"
        hide[:fillcolor] = "lavenderblush:dimgrey"
        hide[:gradientangle] = 0
        hide[:fontname] = FONT
        hide[:fontsize] = 20
        hide[:color] = "midnightblue"
        offset = @data.input.size
        hidden_count = @data.hidden.count
        hidden_sizes = @data.hidden.sizes
        hidden_count.times do |x|
          size = hidden_sizes[x]
          size.times do |y|
#            val = @data.hidden.values[x][y]
            val = @data.hidden.values[x][@data.mapping.hidden[x][y]]
            val_s = sprintf("%0.2f", val)
            @nodes << hide.add_node((offset + y).to_s, label: val_s, fontcolor: "gray7", style: "filled", gradientangle: 33,
              color: "midnightblue", fillcolor: "yellow;#{val}:deepskyblue1", fontname: FONT)
          end
          offset += size
        end
      end
    end

    def build_output
      @graph.add_subgraph(@data.output.name, GraphViz.new("cluster_3", type: :subgraph)) do |outp|
        outp[:label] = "#{@data.output.name}"
        outp[:labelloc] = "bottom"
        outp[:labeljust] = "center"
        outp[:style] = "filled"
        outp[:fillcolor] = "lightgreen:green"
        outp[:gradientangle] = 90
        outp[:fontname] = FONT
        outp[:fontsize] = 20
        output_size = @data.output.size
        output_size.times do |x|
          val_s = build_label(@data.output.values, @data.mapping.output[x])
          hidden_size = @data.hidden.sizes.sum
          offset = @data.input.size + hidden_size
          @nodes << outp.add_node((offset + x).to_s, label: val_s, style: "filled",
            color: "midnightblue", fillcolor: "orange:firebrick", fontname: FONT)
        end
      end
    end

    def build_input_edges
      input_size = @data.input.size
      first_hidden_size = @data.hidden.sizes.first

      low_input_size = (input_size / 2) - 1
      high_input_size = low_input_size + 1
      low_input_size.downto(0) do |low_size|
        first_hidden_size.times do |y|
          offset = 0
          @graph.add_edge(@nodes[offset + low_size], @nodes[offset + @data.input.size + y],
                          color: "steelblue4",
                          arrowsize: 0.7,
                          arrowhead: "normal",
                          headport: "n",
                          tailport: "s")
        end
        first_hidden_size.times do |y|
          offset = 0
          @graph.add_edge(@nodes[offset + high_input_size], @nodes[offset + @data.input.size + y],
                          color: "steelblue4",
                          arrowsize: 0.7,
                          arrowhead: "normal",
                          headport: "n",
                          tailport: "s")
        end
        high_input_size += 1
      end
    end

    def build_hidden_edges
      offset = @data.input.size
      hidden_count = @data.hidden.count
      hidden_sizes = @data.hidden.sizes
      hidden_count.times do |x|
        next if x == 0
        size_in = hidden_sizes[x - 1]
        size_out = hidden_sizes[x]
        size_in.times do |y|
          size_out.times do |z|
            @graph.add_edge(@nodes[offset + y], @nodes[offset + size_in + z],
              color: "cornsilk4",
              arrowsize: 0.7,
              arrowhead: "none",
              headport: "n",
              tailport: "s")
          end
        end
        offset += size_in
      end
    end

    def build_output_edges
      output_size = @data.output.size
      last_hidden_size = @data.hidden.sizes.last
      hidden_size = @data.hidden.sizes.sum
      last_hidden_size.times do |x|
        output_size.times do |y|
          offset = @data.input.size + hidden_size
          @graph.add_edge(@nodes[offset - last_hidden_size + x], @nodes[offset + y],
            color: "steelblue4",
            arrowsize: 0.7,
            arrowhead: "normal",
            headport: "n",
            tailport: "s")
        end
      end
    end

    def build_clusters
      build_input
      build_hidden
      build_output
    end

    def build_edges
      build_input_edges
      build_hidden_edges
      build_output_edges
    end

    def build
      @graph[:labelloc] = "top"
      @graph[:splines] = "line"
      @graph[:bgcolor] = "lavender"
      @graph[:fontname] = FONT
      @graph[:fontcolor] = "grey8"
      @graph[:fontsize] = 20
      @graph[:label] = @title
      @graph[:nodesep] = 0.5
      @graph[:ranksep] = 0.5

      init_mapping
      build_clusters
      build_edges
      build_mapping
      build_clusters
    end

    def to_s
      @graph.to_s
    end

    def generate
      `echo '#{to_s}' | dot -Tsvg -opublic/test.svg`
      cmd = `echo '#{to_s}' | dot -Tplain`
      viz = cmd.split("\n")
      p viz
    end

    def build_mapping
      # parse mapping
      cmd = `echo '#{to_s}' | dot -Tplain`
      viz = cmd.split("\n")
      viz.shift

      mapping = Mapping.new
      offset = 0
      sizes = [@data.input.size]
      @data.hidden.count.times { sizes << @data.hidden.sizes[0] }
      sizes << @data.output.size
      hidden_mapping = Array(Array(Int32)).new
      sub_count = 2 + @data.hidden.count
      sub_count.times do |sub|
        map = Array(Float64).new
        sizes[sub].times do |x|
          map << viz[offset + x].split(" ")[2].to_f64
        end
        offset += sizes[sub]

        # convert to order
        temp = Array(Int32).new
        sizes[sub].times do |x|
          idx = map.index(map.min).not_nil!
          temp << idx
          map[idx] = Float64::MAX
        end
        case sub
        when 0
          puts "input_size"
          mapping.input = temp
        when 1 + @data.hidden.count
          puts "output size"
          mapping.output = temp
        else
          puts "hidden size"
          print "temp: "
          p temp
          hidden_mapping << temp
        end
      end
      mapping.hidden = hidden_mapping
      @data.mapping = mapping
      p @data.mapping
    end

    def delete_hidden
      @graph.delete_subgraph("hidden")
    end

    def debug
      p @graph
    end

    def init_mapping
      temp = [] of Int32
      @data.input.size.times do |x|
        temp << x
      end
      @data.mapping.input = temp

      temp = [] of Int32
      @data.output.size.times do |x|
        temp << x
      end
      @data.mapping.output = temp

      hidden_mapping = [] of Array(Int32)
      @data.hidden.count.times do |x|
        temp = [] of Int32
        @data.hidden.sizes[x].times do |y|
          temp << y
        end
        hidden_mapping << temp
      end
      @data.mapping.hidden = hidden_mapping
    end
  end
end

def load_acc(accumulators, count, size)
  if Random.rand(1.0) > 0.5
    if (accumulators[count][size] + 0.05).round(3) < 0.95
      accumulators[count][size] = (accumulators[count][size] + 0.05).round(3)
    end
  else
    if (accumulators[count][size] - 0.05).round(3) > 0.05
      accumulators[count][size] = (accumulators[count][size] - 0.05).round(3)
    end
  end
end

INPUT_SIZE = 6
HIDDEN_COUNT = 4
HIDDEN_SIZE = 4
OUTPUT_SIZE = 2

accumulators = Array.new(HIDDEN_COUNT) { Array.new(HIDDEN_SIZE) { Random.rand(0.95) } }
gv = Gviz::Visualizer.new("Sequential Ordering\n\n")
gv.input = {name: "Inputs",
            size: INPUT_SIZE}
gv.hidden = {count:  HIDDEN_COUNT,
             sizes:  Array.new(HIDDEN_COUNT) { HIDDEN_SIZE },
             values: accumulators}
gv.output = {name: "Outputs",
             size: OUTPUT_SIZE}
gv.build
gv.generate

low_hidden_count = (HIDDEN_COUNT / 2) - 1
high_count = low_hidden_count + 1

ready = false
spawn do
  loop do
    HIDDEN_COUNT.times do |count|
      HIDDEN_SIZE.times do |size|
        accumulators[count][size] = (count * HIDDEN_SIZE + size).to_f64  / 100.0
        Fiber.yield
      end
      Fiber.yield
    end
#    HIDDEN_SIZE.times do |size|
#      HIDDEN_COUNT.times do |count|
#        if Random.rand(1.0) > 0.5
#          if (accumulators[count][size] + 0.05).round(3) < 0.95
#            accumulators[count][size] = (accumulators[count][size] + 0.05).round(3)
#          end
#        else
#          if (accumulators[count][size] - 0.05).round(3) > 0.05
#            accumulators[count][size] = (accumulators[count][size] - 0.05).round(3)
#          end
#        end
#        Fiber.yield
#      end
#      Fiber.yield
#    end

    gv.delete_hidden
    gv.hidden = {count:  HIDDEN_COUNT,
                 sizes:  Array.new(HIDDEN_COUNT) { HIDDEN_SIZE },
                 values: accumulators}
    ready = false
    gv.build_hidden
    gv.generate
    ready = true
    sleep 1
  end
end

get "/" do |env|
  env.redirect "/index.html"
end

get "/isready" do |env|
  ready ? "ready" : "busy"
end

Kemal.run
