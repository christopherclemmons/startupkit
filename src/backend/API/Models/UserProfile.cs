using System.ComponentModel.DataAnnotations;

namespace API.Models;

// Example entity for a boilerplate API. Replace with your domain entities.
public class UserProfile : BaseEntity
{
    [MaxLength(100)]
    public string? DisplayName { get; set; }

    [MaxLength(500)]
    public string? Bio { get; set; }
}
