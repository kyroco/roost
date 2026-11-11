defmodule Roost.JobsAndMigrationsTest do
  use ExUnit.Case, async: true

  describe "jobs/0" do
    test "returns the crontab entries present apps register, in registration order, as Oban takes them" do
      assert Roost.jobs() == [
               {"0 3 * * *", Roost.Test.NightlyWorker},
               {"*/5 * * * *", Roost.Test.NightlyWorker, queue: :maintenance}
             ]
    end

    test "leaves out an entry whose worker is not in the running release" do
      refute Enum.any?(Roost.jobs(), &(elem(&1, 1) == Roost.Test.AbsentWorker))
    end
  end

  describe "migrations/1" do
    test "returns, for a repo, each present app's migrations folder inside that app" do
      assert Roost.migrations(Roost.Test.Repo) == [
               Application.app_dir(:roost, "priv/repo/migrations")
             ]
    end

    test "returns nothing for a repo no present app names" do
      assert Roost.migrations(Some.Other.Repo) == []
    end
  end

  describe "load_registered/0" do
    test "loads every registered app the release carries and skips the ones it does not" do
      assert Roost.load_registered() == :ok
      assert Roost.present?(:roost)
      refute Roost.present?(:not_in_release)
    end
  end
end
