require "./gviz/*"
require "graphviz"

module Gviz
  class Visualizer
    @data : Data

    property data : Data

    struct Data
      property input : NamedTuple(name: String, size: Int32, values: Array(Float64))
      property hidden : NamedTuple(count: Int32, sizes: Array(Int32), values: Array(Array(Float64)))
      property output : NamedTuple(name: String, size: Int32, values: Array(Float64))

      def initialize(@input = {name: "", size: 0, values: Array(Float64).new},
                     @output = {name: "", size: 0, values: Array(Float64).new},
                     @hidden = {count: 1, sizes: Array(Int32).new, values: Array(Array(Float64)).new})
      end
    end

    def initialize
      @data = Data.new
      @graph = GraphViz.new(:G, type: :digraph)
      @nodes = Array(GraphViz::Node).new
    end

    def build_input
      @graph.add_subgraph(@data.input[:name], GraphViz.new("cluster_0", type: :subgraph)) do |inp|
        inp[:label] = "#{@data.input[:name]} (#{@data.input[:size].to_s})"
        inp[:labelloc] = "top"
        inp[:labeljust] = "center"
        inp[:style] = "filled"
        inp[:fillcolor] = "green"
        input_size = @data.input[:size]
        input_size.times do |x|
          val = @data.input[:values].empty? ? "" : @data.input[:values][x]
          val_s = sprintf("%0.2f", val)
          @nodes << inp.add_node(x.to_s, label: val_s, style: "filled", color: "green", fillcolor: "lightblue")
        end
      end
    end

    def build_hidden
      @graph.add_subgraph("hide", GraphViz.new("cluster_1", type: :subgraph)) do |hide|
        hide[:label] = ""
        hide[:style] = "filled"
        hide[:fillcolor] = "lightgrey"
        offset = @data.input[:size]
        hidden_count = @data.hidden[:count]
        hidden_sizes = @data.hidden[:sizes]
        hidden_count.times do |x|
          size = hidden_sizes[x]
          size.times do |y|
            val = @data.hidden[:values][x].empty? ? "" : @data.hidden[:values][x][y]
            val_s = sprintf("%0.2f", val)
            @nodes << hide.add_node((offset + y).to_s, label: val_s, style: "filled",
              color: "blue", fillcolor: "cyan")
          end
          offset += size
        end
      end
    end

    def build_output
      @graph.add_subgraph(@data.output[:name], GraphViz.new("cluster_2", type: :subgraph)) do |outp|
        outp[:label] = "#{@data.output[:name]} (#{@data.output[:size].to_s})"
        outp[:labelloc] = "bottom"
        outp[:labeljust] = "center"
        outp[:style] = "filled"
        outp[:fillcolor] = "green"
        output_size = @data.output[:size]
        output_size.times do |x|
          val = @data.output[:values].empty? ? "" : @data.output[:values][x]
          val_s = sprintf("%0.2f", val)
          hidden_size = @data.hidden[:sizes].sum
          offset = @data.input[:size] + hidden_size
          @nodes << outp.add_node((offset + x).to_s, label: val_s, style: "filled",
            color: "blue", fillcolor: "orange")
        end
      end
    end

    def build_input_edges
      input_size = @data.input[:size]
      first_hidden_size = @data.hidden[:sizes].first
      input_size.times do |x|
        first_hidden_size.times do |y|
          offset = 0
          @graph.add_edge(@nodes[offset + x], @nodes[offset + @data.input[:size] + y],
            color: "lightgrey", arrowsize: 1, arrowhead: "empty", style: "dotted")
        end
      end
    end

    def build_hidden_edges
      offset = @data.input[:size]
      hidden_count = @data.hidden[:count]
      hidden_sizes = @data.hidden[:sizes]
      hidden_count.times do |x|
        next if x == 0
        size1 = hidden_sizes[x - 1]
        size2 = hidden_sizes[x]
        size1.times do |y|
          size2.times do |z|
            @graph.add_edge(@nodes[offset + y], @nodes[offset + size1 + z],
              color: "lightgrey", arrowsize: 1, arrowhead: "none", style: "dotted")
          end
        end
        offset += size1
      end
    end

    def build_output_edges
      output_size = @data.output[:size]
      last_hidden_size = @data.hidden[:sizes].last
      hidden_size = @data.hidden[:sizes].sum
      last_hidden_size.times do |x|
        output_size.times do |y|
          offset = @data.input[:size] + hidden_size
          @graph.add_edge(@nodes[offset - last_hidden_size + x], @nodes[offset + y],
            color: "lightgrey", arrowsize: 1, arrowhead: "empty", style: "dotted")
        end
      end
    end

    def build
      @graph[:label] = "Graph"
      @graph[:style] = "filled"
      @graph[:color] = "red"
      @graph[:labelloc] = "top"
      @graph[:splines] = "line"
      build_input
      build_hidden
      build_output
      build_input_edges
      build_hidden_edges
      build_output_edges
    end

    def to_s
      @graph.to_s
    end

    def generate
      `echo '#{@graph.to_s}' | dot -Tsvg -otemp.svg && xsltproc --novalid notugly.xsl temp.svg >test.svg`
    end
  end
end

gv = Gviz::Visualizer.new
gv.data.input = {name: "Input", size: 8, values: [0.1, 0.2, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3]}
gv.data.hidden = {count:  4,
                  sizes:  [12, 14, 10, 8],
                  values: [[0.1, 0.2, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3],
                           [0.1, 0.2, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3],
                           [0.1, 0.2, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3],
                           [0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3]]}
gv.data.output = {name:   "Output",
                  size:   5,
                  values: [0.1, 0.2, 0.3, 0.2, 0.3]}
gv.build
gv.generate
