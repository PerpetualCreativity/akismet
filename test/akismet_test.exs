defmodule AkismetTest do
  use ExUnit.Case

  setup_all do
    case System.get_env("TEST_AKISMET_ELIXIR_KEY") do
      nil -> {:error, "Environment variable TEST_AKISMET_ELIXIR_KEY not set."}
      key -> {:ok, key: key, strct: %Akismet{key: key, blog: "https://example.com"}}
    end
  end

  test "init", state do
    assert Akismet.init("https://example.com") == :key_not_set
    :ok = System.put_env("AKISMET_KEY", "wrong_key")
    assert Akismet.init("https://example.com") == :invalid_key
    :ok = System.put_env("AKISMET_KEY", state.key)
    assert Akismet.init("https://example.com") == {:ok, state.strct}
  end

  test "check comment", state do
    assert Akismet.check_comment(state.strct, "127.0.0.1",
             comment_author_email: "akismet-guaranteed-spam@example.com"
           ) == :spam

    assert Akismet.check_comment(state.strct, "127.0.0.1",
             comment_author: "akismet-guaranteed-spam"
           ) == :spam

    assert Akismet.check_comment(state.strct, "127.0.0.1",
             user_role: "administrator",
             is_test: "true"
           ) == :ham
  end

  test "submit spam and ham", state do
    assert Akismet.submit_spam(state.strct, "127.0.0.1", []) == :success
    assert Akismet.submit_ham(state.strct, "127.0.0.1", []) == :success
  end

  test "usage limit", state do
    res = Akismet.usage_limit(state.strct)
    assert res != :error
  end
end
