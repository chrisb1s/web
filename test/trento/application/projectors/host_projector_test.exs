defmodule Trento.HostProjectorTest do
  use ExUnit.Case
  use Trento.DataCase

  import Trento.Factory

  alias Trento.{
    AzureProviderReadModel,
    HostProjector,
    HostReadModel
  }

  alias Trento.Domain.AzureProvider

  alias Trento.Domain.Events.{
    HeartbeatFailed,
    HeartbeatSucceded,
    HostDetailsUpdated,
    ProviderUpdated
  }

  alias Trento.ProjectorTestHelper
  alias Trento.Repo

  @moduletag :integration

  setup do
    %HostReadModel{id: host_id} = host_projection()

    %{host_id: host_id}
  end

  test "should project a new host when HostRegistered event is received" do
    event = host_registered_event()

    ProjectorTestHelper.project(HostProjector, event, "host_projector")
    host_projection = Repo.get!(HostReadModel, event.host_id)

    assert event.host_id == host_projection.id
    assert event.hostname == host_projection.hostname
    assert event.ip_addresses == host_projection.ip_addresses
    assert event.agent_version == host_projection.agent_version
    assert event.heartbeat == host_projection.heartbeat
  end

  test "should update an existing host when HostDetailsUpdated event is received", %{
    host_id: host_id
  } do
    event = %HostDetailsUpdated{
      host_id: host_id,
      hostname: Faker.StarWars.character(),
      ip_addresses: [Faker.Internet.ip_v4_address()],
      agent_version: Faker.StarWars.planet(),
      cpu_count: Enum.random(1..16),
      total_memory_mb: Enum.random(1..128),
      socket_count: Enum.random(1..16),
      os_version: Faker.App.version()
    }

    ProjectorTestHelper.project(HostProjector, event, "host_projector")
    host_projection = Repo.get!(HostReadModel, event.host_id)

    assert event.host_id == host_projection.id
    assert event.hostname == host_projection.hostname
    assert event.ip_addresses == host_projection.ip_addresses
    assert event.agent_version == host_projection.agent_version
  end

  test "should update the heartbeat field to passing status when HeartbeatSucceded is received",
       %{host_id: host_id} do
    event = %HeartbeatSucceded{
      host_id: host_id
    }

    ProjectorTestHelper.project(HostProjector, event, "host_projector")
    host_projection = Repo.get!(HostReadModel, event.host_id)

    assert :passing == host_projection.heartbeat
  end

  test "should update the heartbeat field to critical status when HeartbeatFailed is received", %{
    host_id: host_id
  } do
    event = %HeartbeatFailed{
      host_id: host_id
    }

    ProjectorTestHelper.project(HostProjector, event, "host_projector")
    host_projection = Repo.get!(HostReadModel, event.host_id)

    assert :critical == host_projection.heartbeat
  end

  test "should update the provider field when ProviderUpdated is received with Azure provider type",
       %{
         host_id: host_id
       } do
    event = %ProviderUpdated{
      host_id: host_id,
      provider: :azure,
      provider_data: %AzureProvider{
        vm_name: "vmhdbdev01",
        data_disk_number: 7,
        location: "westeurope",
        offer: "sles-sap-15-sp3-byos",
        resource_group: "/subscriptions/00000000-0000-0000-0000-000000000000",
        sku: "gen2",
        vm_size: "Standard_E4s_v3"
      }
    }

    ProjectorTestHelper.project(HostProjector, event, "host_projector")
    host_projection = Repo.get!(HostReadModel, event.host_id)

    expected_azure_model = %AzureProviderReadModel{
      vm_name: "vmhdbdev01",
      data_disk_number: 7,
      location: "westeurope",
      offer: "sles-sap-15-sp3-byos",
      resource_group: "/subscriptions/00000000-0000-0000-0000-000000000000",
      sku: "gen2",
      vm_size: "Standard_E4s_v3"
    }

    assert :azure == host_projection.provider
    assert expected_azure_model == host_projection.provider_data
  end
end