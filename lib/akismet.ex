defmodule Akismet do
  @moduledoc """
  Easily check comments with Akismet from Elixir.

  Note: You need to provide `AKISMET_KEY` as an environment variable.

  ## Examples

  Export your Akismet key...
  ```sh
  export AKISMET_KEY='myakismetkey123'
  ```

  Then use this library from Elixir:
  ```elixir
  {:ok, akismet} = Akismet.init("https://example.com")
  result0 = Akismet.check_comment(akismet, user_ip, [comment_content: content, comment_author_email: email, ...])
  result1 = Akismet.submit_spam(akismet, user_ip, [comment_content: content, comment_author_email: email, ...])
  result2 = Akismet.submit_ham(akismet, user_ip, [comment_content: content, comment_author_email: email, ...])
  {:ok, %{limit: limit, usage: usage, percentage: pct, throttled: throttled}} = Akismet.usage_limit(akismet)
  ```

  (You should probably handle errors, these are just quick examples.)
  """

  defstruct key: "", blog: ""

  @doc """
  Initializes the client. This verifies the API key, set in the environment
  variable `AKISMET_KEY`.

  Returns

  - `{:ok, Akismet}`: API key is valid and successfully verified,
  - `:key_not_set`: the environment variable `AKISMET_KEY` is not set,
  - `:invalid_key`: your API key is not valid,
  - or `:error`: couldn't access the Akismet endpoint.
  """
  def init(blog) do
    case System.fetch_env("AKISMET_KEY") do
      {:ok, key} ->
        case post("verify-key", [api_key: key, blog: blog]) do
          {:ok, %{body: "valid"}} -> {:ok, %Akismet{key: key, blog: blog}}
          {:ok, %{body: "invalid"}} -> :invalid_key
          {:error, _} -> :error
        end
      :error -> :key_not_set
    end
  end
 
  @doc """
  Check a comment.

  Arguments:
  
  - the struct returned by `init/1`,
  - the IP of the commenter,
  - and [extra parameters](https://akismet.com/developers/comment-check/) in the format
  `[user_agent: value, comment_type: value]`, etc.

  Returns

  - `:spam`,
  - `:discard_spam`: Akismet says the comment is ["blatant spam"](https://akismet.com/blog/theres-a-ninja-in-your-akismet/) and does not need to be stored,
  - `:ham`,
  - `{:akismet_error, "debug help"}`: Akismet returned an error and the second element
    is the help/debugging message, if it exists.
  - or `:error`: could not access the Akismet endpoint.
  """
  def check_comment(base, user_ip, params) do
    case main_post("comment-check", base, user_ip, params) do
      {:ok, %{body: "true", headers: headers}} -> if get_header(headers, "X-akismet-pro-tip") == "discard", do: :discard_spam, else: :spam
      {:ok, %{body: "false"}} -> :ham
      {:ok, %{body: "invalid", headers: headers}} -> {:akismet_error, get_header(headers, "X-akismet-debug-help")}
      {:error, _} -> :error
    end
  end

  @doc """
  Submit spam.

  Arguments:
  
  - the struct returned by `init/1`,
  - the IP of the commenter,
  - and [extra parameters](https://akismet.com/developers/comment-check/) in the format
  `[user_agent: value, comment_type: value]`, etc.

  Returns

  - `:success`: submitted spam successfully,
  - `:failed`: failed to submit spam,
  - or `:error`: could not access the Akismet endpoint.
  """
  def submit_spam(base, user_ip, params), do: submit_spam_ham("spam", base, user_ip, params)

  @doc """
  Submit ham.

  Arguments:
  
  - the struct returned by `init/1`,
  - the IP of the commenter,
  - and [extra parameters](https://akismet.com/developers/comment-check/) in the format
  `[user_agent: value, comment_type: value]`, etc.

  Returns

  - `:success`: submitted spam successfully,
  - `:failed`: failed to submit spam,
  - or `:error`: could not access the Akismet endpoint.
  """
  def submit_ham(base, user_ip, params), do: submit_spam_ham("ham", base, user_ip, params)

  defp submit_spam_ham(type, base, user_ip, params) do
    case main_post("submit-" <> type, base, user_ip, params) do
      {:ok, %{body: "Thanks for making the web a better place."}} -> :success
      {:ok, _} -> :failed
      {:error, _} -> :error
    end
  end

  @doc """
  Get usage limit.

  Arguments:

  - the struct returned by `init/1`,

  Returns:

  - `{:ok, %{limit: _, usage: _, percentage: _, throttled: _}}` (see
    [Akismet docs on usage limit](https://akismet.com/developers/usage-limit/))
  - `:error`: could not access Akismet endpoint
  """
  def usage_limit(base) do
    case post("usage-limit", [api_key: base.key], "1.2") do
      {:ok, %{body: json_body}} -> {:ok, Jason.decode!(json_body, keys: :atoms)}
      {:error, _} -> :error
    end
  end

  defp post(endpoint, form, version \\ "1.1") do
    HTTPoison.post("https://rest.akismet.com/" <> version <> "/" <> endpoint, {:form, form}, [{"Content-Type", "application/x-www-form-urlencoded"}])
  end

  defp main_post(endpoint, base, user_ip, params) do
    post(endpoint, [{:api_key, base.key}, {:blog, base.blog}, {:user_ip, user_ip} | params])
  end

  defp get_header(headers, header_key) do
    is_header = fn
      {^header_key, _} -> true
      _ -> false
    end
    Enum.find(headers, "", is_header)
  end
end
