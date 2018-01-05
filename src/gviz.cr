require "./gviz/*"
require "graphviz"
require "kemal"

module Gviz
  class Visualizer
    FONT = "Helvetica-Bold"
    SVG = "public/svg/nodes.svg"
    DOT_COMMAND = "dot"

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
        inp[:fillcolor] = "springgreen3:green"
        inp[:gradientangle] = 270
        inp[:fontname] = FONT
        inp[:fontsize] = 20
        input_size = @data.input.size
        input_size.times do |x|
          val_s = build_label(@data.input.values, @data.mapping.input[x])
          @nodes << inp.add_node(x.to_s, label: val_s, style: "filled",
            color: "midnightblue", fillcolor: "orange:firebrick", fontname: FONT)
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
          hidden_sizes[x].times do |y|
            val = @data.hidden.values[x][@data.mapping.hidden[x][y]]
            val_s = build_label(@data.hidden.values[x], @data.mapping.hidden[x][y])
            @nodes << hide.add_node((offset + y).to_s, label: val_s, fontcolor: "gray7", style: "filled", gradientangle: 33,
                                    color: "midnightblue", fillcolor: "yellow;#{val}:deepskyblue1", fontname: FONT)
          end
          offset += hidden_sizes[x]
        end
      end
    end

    def build_output
      @graph.add_subgraph(@data.output.name, GraphViz.new("cluster_3", type: :subgraph)) do |outp|
        outp[:label] = "#{@data.output.name}"
        outp[:labelloc] = "bottom"
        outp[:labeljust] = "center"
        outp[:style] = "filled"
        outp[:fillcolor] = "springgreen3:green"
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

    def outfile
    end

    def cmd(format = "plain", outfile = "")
      `echo '#{to_s}' | #{DOT_COMMAND} -T#{format} -o#{outfile}`
    end

    def start
      build
      generate
    end

    def generate
      cmd("svg", SVG)
    end

    def extract_node_order(map, sub, sizes)
      # convert to order
      temp = Array(Int32).new
      sizes[sub].times do |x|
        idx = map.index(map.min).not_nil!
        temp << idx
        map[idx] = Float64::MAX
      end
      temp2 = Array(Int32).new
      sizes[sub].times do |x|
        idx = temp.index(temp.min).not_nil!
        temp2 << idx
        temp[idx] = Int32::MAX
      end
      temp2
    end

    def build_mapping
      viz = cmd.split("\n")
      viz.shift

      @data.mapping = Mapping.new
      offset = 0
      sizes = [@data.input.size]
      @data.hidden.count.times { |x| sizes << @data.hidden.sizes[x] }
      sizes << @data.output.size
      sub_count = 2 + @data.hidden.count
      sub_count.times do |sub|
        map = Array(Float64).new
        (sizes[sub]).times do |x|
          map << viz[offset + x].split(" ")[2].to_f64
        end
        order = extract_node_order(map, sub, sizes)
        case sub
        when 0
          @data.mapping.input = order
        when 1 + @data.hidden.count
          @data.mapping.output = order
        else # hidden
          (sizes[sub]).times do |x|
          end
          @data.mapping.hidden << order
        end
        offset += sizes[sub]
      end
    end

    def update
      delete_hidden
      generate
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
      hidden_mapping = Array(Array(Int32)).new
      @data.hidden.count.times do |x|
        hidden_mapping << Array.new(@data.hidden.sizes[x]) { |x| x }
      end
      @data.mapping.hidden = hidden_mapping
    end
  end
end
