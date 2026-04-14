using Microsoft.EntityFrameworkCore;
using API.Contracts.Profiles;
using API.Data;
using API.Models;

namespace API.Services;

public class ProfileService
{
    private readonly ApplicationDbContext _context;

    public ProfileService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<UserProfileDto?> GetProfileAsync(int id)
    {
        var profile = await _context.UserProfiles
            .FirstOrDefaultAsync(p => p.Id == id);

        if (profile == null)
            return null;

        return new UserProfileDto
        {
            Id = profile.Id,
            DisplayName = profile.DisplayName,
            Bio = profile.Bio
        };
    }

    public async Task<UserProfileDto> CreateOrUpdateProfileAsync(UserProfileDto profileDto)
    {
        var profile = await _context.UserProfiles
            .FirstOrDefaultAsync(p => p.Id == profileDto.Id);

        if (profile == null)
        {
            profile = new UserProfile
            {
                Id = profileDto.Id,
                DisplayName = profileDto.DisplayName,
                Bio = profileDto.Bio,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };
            _context.UserProfiles.Add(profile);
        }
        else
        {
            profile.DisplayName = profileDto.DisplayName;
            profile.Bio = profileDto.Bio;
            profile.UpdatedAt = DateTime.UtcNow;
            _context.UserProfiles.Update(profile);
        }

        await _context.SaveChangesAsync();

        return new UserProfileDto
        {
            Id = profile.Id,
            DisplayName = profile.DisplayName,
            Bio = profile.Bio
        };
    }
} 
