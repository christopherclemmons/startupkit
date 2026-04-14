using System.Net;
using System.Net.Http.Json;
using API.Contracts.Profiles;
using Xunit;

namespace API.Tests;

public class UserProfileControllerTests
{
    [Fact]
    public async Task Health_ReturnsOk()
    {
        await using var factory = new ApiApplicationFactory();
        using var client = factory.CreateClient();

        var response = await client.GetAsync("/api/profile/health");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("\"API is running\"", await response.Content.ReadAsStringAsync());
    }

    [Fact]
    public async Task GetProfile_WithInvalidId_ReturnsNotFound()
    {
        await using var factory = new ApiApplicationFactory();
        using var client = factory.CreateClient();

        var response = await client.GetAsync("/api/profile/999");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task PutProfile_CreatesProfile_AndGetReturnsProfile()
    {
        await using var factory = new ApiApplicationFactory();
        using var client = factory.CreateClient();

        var profile = new UserProfileDto
        {
            Id = 1,
            DisplayName = "Test User",
            Bio = "Test bio"
        };

        var putResponse = await client.PutAsJsonAsync("/api/profile", profile);
        putResponse.EnsureSuccessStatusCode();

        var storedProfile = await putResponse.Content.ReadFromJsonAsync<UserProfileDto>();
        Assert.NotNull(storedProfile);
        Assert.Equal(profile.Id, storedProfile.Id);
        Assert.Equal(profile.DisplayName, storedProfile.DisplayName);
        Assert.Equal(profile.Bio, storedProfile.Bio);

        var getResponse = await client.GetAsync($"/api/profile/{profile.Id}");
        getResponse.EnsureSuccessStatusCode();

        var returnedProfile = await getResponse.Content.ReadFromJsonAsync<UserProfileDto>();
        Assert.NotNull(returnedProfile);
        Assert.Equal(profile.Id, returnedProfile.Id);
        Assert.Equal(profile.DisplayName, returnedProfile.DisplayName);
        Assert.Equal(profile.Bio, returnedProfile.Bio);
    }

    [Fact]
    public async Task PutProfile_WithoutId_ReturnsBadRequest()
    {
        await using var factory = new ApiApplicationFactory();
        using var client = factory.CreateClient();

        var response = await client.PutAsJsonAsync("/api/profile", new
        {
            displayName = "Missing Id",
            bio = "Invalid payload"
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }
}
