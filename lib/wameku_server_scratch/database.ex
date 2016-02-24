use Amnesia

defdatabase Database do
  deftable Client, [:name, :active, :notifier, :last_checked], type: :set do
    @type t :: %Client{name: String.t, active: Boolean.t, notifier: List.t, last_checked: integer}

    def insert(self) do
      f = fn() -> self |> Client.write end
      Amnesia.transaction(f)
    end

    def find(name) do
      f = fn() -> Client.read(name) end
      Amnesia.transaction(f)
    end
  end
end
