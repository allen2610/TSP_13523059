# Display simple title
def display_title
  puts "\n=== Traveling Salesman Problem Solver ===\n\n"
end

# Parse graph from a file into a square adjacency matrix
def parse_graph_file(path)
  adjacency = []
  line_idx = 0
  expected_len = nil

  File.foreach(path) do |line|
    next if line.strip.empty?
    line_idx += 1

    entries = line.strip.split.map do |item|
      case item.downcase
      when 'inf', 'infinity', '∞', '9999', '-1'
        Float::INFINITY
      else
        num = Float(item) rescue raise("Invalid number '#{item}' on line #{line_idx}")
        raise "Negative weight not allowed: '#{item}' on line #{line_idx}" if num < 0
        num
      end
    end

    expected_len ||= entries.length
    raise "Line #{line_idx} has inconsistent number of columns" if entries.length != expected_len

    adjacency << entries
  end

  raise "Graph file is empty" if adjacency.empty?
  raise "Graph must be square" unless adjacency.length == adjacency[0].length

  adjacency
end

# Output adjacency matrix for visualization
def show_matrix(matrix)
  puts "\nAdjacency Matrix:"
  matrix.each do |row|
    puts row.map { |val| val.infinite? ? "  INF" : format("%6.2f", val) }.join(" ")
  end
  puts
end

# Recursive TSP solver with memoization
def compute_tsp(matrix, current_node, visited_mask, origin, memo_store)
  n = matrix.length

  if visited_mask == (1 << n) - 1
    cost_back = matrix[current_node][origin]
    return [cost_back, [[current_node, origin]]] if cost_back.finite?
    return [Float::INFINITY, []]
  end

  return memo_store[[current_node, visited_mask]] if memo_store.key?([current_node, visited_mask])

  best = Float::INFINITY
  paths = []

  n.times do |next_node|
    next if visited_mask & (1 << next_node) != 0
    next unless matrix[current_node][next_node].finite?

    sub_cost, sub_paths = compute_tsp(matrix, next_node, visited_mask | (1 << next_node), origin, memo_store)
    next unless sub_cost.finite?

    total = matrix[current_node][next_node] + sub_cost

    if total < best
      best = total
      paths = sub_paths.map { |p| [current_node] + p }
    elsif total == best
      paths += sub_paths.map { |p| [current_node] + p }
    end
  end

  memo_store[[current_node, visited_mask]] = [best, paths]
end

# Program entry
display_title

file_input = ARGV[0]

until file_input && file_input.end_with?(".txt") && File.exist?(file_input)
  print "Enter path to .txt file: "
  user_input = gets.strip
  file_input = File.join("../test", user_input)

  unless file_input.end_with?(".txt")
    puts "Error: Must be a .txt file."
    file_input = nil
    next
  end

  unless File.exist?(file_input)
    puts "Error: File not found at '#{file_input}'"
    file_input = nil
  end
end

begin
  adj_matrix = parse_graph_file(file_input)
rescue => e
  puts "Error reading graph: #{e.message}"
  exit(1)
end

start_idx = nil
loop do
  print "Select starting city index (1 to #{adj_matrix.size}): "
  input = gets.strip
  if input =~ /^\d+$/ && (1..adj_matrix.size).include?(input.to_i)
    start_idx = input.to_i - 1
    break
  else
    puts "Invalid input. Enter a number between 1 and #{adj_matrix.size}."
  end
end

show_matrix(adj_matrix)

memo = {}
initial_mask = 1 << start_idx

min_cost, tour_paths = compute_tsp(adj_matrix, start_idx, initial_mask, start_idx, memo)

if !min_cost.finite? || tour_paths.empty?
  puts "No complete tour is possible from this graph."
else
  puts "\nOptimal TSP Tour Found!"
  puts "Minimum Tour Cost: #{'%.2f' % min_cost}"
  puts "Total Optimal Routes: #{tour_paths.size}"
  tour_paths.each_with_index do |route, idx|
    puts "  Route ##{idx + 1}: " + route.map { |v| v + 1 }.join(" -> ")
  end
end
