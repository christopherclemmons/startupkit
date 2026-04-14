using System.ComponentModel.DataAnnotations;

namespace API.Contracts.Profiles;

public class UserProfileDto
{
    [Range(1, int.MaxValue)]
    public int Id { get; set; }

    [MaxLength(100)]
    public string? DisplayName { get; set; }

    [MaxLength(500)]
    public string? Bio { get; set; }
}
