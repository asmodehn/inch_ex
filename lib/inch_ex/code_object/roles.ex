defmodule InchEx.CodeObject.Roles do
  @many_parameters_threshold 5

  @role_with_many_children "with_many_children"
  @role_with_children "with_children"
  @role_in_root "in_root"
  @role_with_doc "with_doc"
  @role_without_doc "without_doc"
  @role_with_codeexample "with_code_example"
  @role_without_codeexample "without_code_example"
  @role_with_many_parameters "with_many_parameters"
  @role_with_bang_name "with_bang_name"
  @role_with_metadata "with_metadata"
  @role_with_questioning_name "with_questioning_name"
  @role_function_parameter_with_mention "with_function_parameter_mention"
  @role_function_parameter_without_mention "without_function_parameter_mention"

  alias InchEx.CodeObject.Doc

  def run(item) do
    [
      in_root(item),
      with_withoutdoc(item),
      with_withoutcodeexample(item),
      children(item),
      parameters(item),
      name(item),
      metadata(item),
      functionparameter_with_withoutmention(item)
    ]
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&to_string/1)
  end

  def in_root(%{"name" => name}) do
    depth =
      name
      |> String.split(".")
      |> Enum.count()

    if depth == 1, do: to_role(@role_in_root)
  end

  def children(%{"children" => x}) when x > 20, do: to_role(@role_with_many_children)
  def children(%{"children" => x}) when x > 1, do: to_role(@role_with_children)
  def children(_), do: nil

  def with_withoutdoc(item) do
    if Doc.present?(item) do
      to_role(@role_with_doc)
    else
      to_role(@role_without_doc)
    end
  end

  def with_withoutcodeexample(item) do
    if Doc.has_code_example?(item) do
      to_role(@role_with_codeexample)
    else
      to_role(@role_without_codeexample)
    end
  end

  def parameters(item) do
    names = item |> fun_params() |> List.wrap()

    if Enum.count(names) > @many_parameters_threshold do
      to_role(@role_with_many_parameters)
    end
  end

  def name(%{"name" => name}) do
    case Regex.scan(~r/([\!\?])\/\d$/, name) do
      [[_, "!"]] -> to_role(@role_with_bang_name)
      [[_, "?"]] -> to_role(@role_with_questioning_name)
      [] -> nil
    end
  end

  defp metadata(%{"metadata" => metadata}) do
    Enum.map(metadata, fn {key, _value} ->
      to_role(@role_with_metadata, key)
    end)
  end

  defp functionparameter_with_withoutmention(%{"signature" => _} = item) do
    names = fun_params(item)
    doc = Doc.get(item)

    Enum.map(names, fn name ->
      if Doc.mentions?(doc, name) do
        to_role(@role_function_parameter_with_mention, name)
      else
        to_role(@role_function_parameter_without_mention, name)
      end
    end)
  end

  defp functionparameter_with_withoutmention(_), do: nil

  defp fun_params(%{"signature" => list}) do
    {_, list} = Macro.prewalk(list, [], &traverse_fun_params/2)

    list
  end

  defp fun_params(_), do: nil

  defp traverse_fun_params([name, _meta, nil], acc) do
    {nil, [name] ++ acc}
  end

  defp traverse_fun_params(item, acc) when is_list(item) do
    {item, acc}
  end

  defp traverse_fun_params(_item, acc) do
    # IO.inspect(item, label: "traverse_fun_params")

    {nil, acc}
  end

  defp to_role(value), do: to_string(value)
  defp to_role(value, _), do: to_string(value)

  #

  def title(role)

  def title("with_many_children"), do: "Has many children"
  def title("with_children"), do: "Has children"
  def title("in_root"), do: "At the top level"
  def title("with_doc"), do: "Has documentation"
  def title("without_doc"), do: "Misses documentation"
  def title("with_code_example"), do: "Has a code example"
  def title("without_code_example"), do: "Misses a code example"
  def title("with_many_parameters"), do: "Has many parameters"
  def title("with_bang_name"), do: "Has a bang name (ending in `!`)"
  def title("with_questioning_name"), do: "Has a questioning name (ending in `?`)"
  def title("with_function_parameter_mention"), do: "Mentions function parameter"
  def title("without_function_parameter_mention"), do: "Misses mentioning function parameter"

  def title(role), do: "Missing title for `#{role}`."
end