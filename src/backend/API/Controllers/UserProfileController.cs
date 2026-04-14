using API.Contracts.Profiles;
using API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace API.Controllers;

[Route("api/profile")]
public sealed class UserProfileController : BaseApiController
{
    private readonly ProfileService _profileService;

    public UserProfileController(ProfileService profileService)
    {
        _profileService = profileService;
    }

    [HttpGet("{id:int:min(1)}")]
    [ProducesResponseType<UserProfileDto>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<UserProfileDto>> GetProfileAsync(int id)
    {
        var profile = await _profileService.GetProfileAsync(id);
        if (profile is null)
        {
            return NotFound();
        }

        return Ok(profile);
    }

    [HttpPut]
    [ProducesResponseType<UserProfileDto>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<UserProfileDto>> UpsertProfileAsync([FromBody] UserProfileDto profileDto)
    {
        var updatedProfile = await _profileService.CreateOrUpdateProfileAsync(profileDto);
        return Ok(updatedProfile);
    }

    [AllowAnonymous]
    [HttpGet("health")]
    [ProducesResponseType<string>(StatusCodes.Status200OK)]
    public ActionResult<string> Health()
    {
        return Ok("API is running");
    }
}
