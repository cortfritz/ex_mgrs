msg_file = System.argv() |> List.first()

unless msg_file do
  IO.puts(:stderr, "No commit message file provided")
  System.halt(1)
end

msg = File.read!(msg_file) |> String.trim()

pattern = ~r/^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?!?: .+/

unless Regex.match?(pattern, msg) do
  IO.puts(:stderr, """

  Invalid commit message format.
  Must follow Conventional Commits: <type>(<scope>): <description>
  Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert

  Got: #{msg}
  """)

  System.halt(1)
end
