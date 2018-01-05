require "./src/*"

# RANDOM true = random, RANDOM false = sequential
RANDOM = true

INPUT_SIZE = 6
HIDDEN_COUNT = 2
HIDDEN_SIZES = [6, 8]
OUTPUT_SIZE = 4
INTERVAL = 1

subcount = HIDDEN_COUNT
accumulators = Array.new(HIDDEN_COUNT) { |x| Array.new(HIDDEN_SIZES[x]) { |y| Random.rand(0.95) } }
server = Server.new
gv = Gviz::Visualizer.new("Testing Testing\n\n")
gv.input = {name: "Inputs",
            size: INPUT_SIZE}
gv.hidden = {count:  HIDDEN_COUNT,
             sizes: HIDDEN_SIZES,
             values: accumulators}
gv.output = {name: "Outputs",
             size: OUTPUT_SIZE}
gv.start

if RANDOM
  spawn do
    loop do
      HIDDEN_COUNT.times do |count|
        HIDDEN_SIZES[count].times do |size|
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
      end
      gv.delete_hidden
      gv.hidden = { count: HIDDEN_COUNT,
                    sizes: HIDDEN_SIZES,
                    values: accumulators }

      server.ready = false
      gv.build_hidden
      gv.generate
      server.ready = true
      sleep INTERVAL
    end
  end
else
  spawn do
    loop do
      offset = 0
      HIDDEN_COUNT.times do |count|
        HIDDEN_SIZES[count].times do |size|
          accumulators[count][size] = (offset + size).to_f64  / 100.0
        end
        offset += HIDDEN_SIZES[count]
      end
      gv.delete_hidden
      gv.hidden = { count: HIDDEN_COUNT,
                    sizes: HIDDEN_SIZES,
                    values: accumulators }
      server.ready = false
      gv.build_hidden
      gv.generate
      server.ready = true
      sleep INTERVAL
    end
  end
end

server.run
