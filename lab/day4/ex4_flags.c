#include <stdio.h>
#include <string.h>

/* A staff badge for the warehouse. The access code packs every field into one 32-bit number. */
enum level { LEVEL_VISITOR, LEVEL_STAFF, LEVEL_SUPERVISOR, LEVEL_MANAGER, LEVEL_AUDITOR };

#define PERM_DOCK    0x01
#define PERM_COLD    0x02
#define PERM_HAZMAT  0x04
#define PERM_NIGHT   0x08
#define PERM_VAULT   0x10
#define PERM_TEMP    0x80          /* a temporary badge */

#define SITE_TAG     0x5744        /* "WD", the site every badge must belong to */
#define VAULT_ZONE   7
#define VAULT_NEEDS  (PERM_VAULT | PERM_HAZMAT | PERM_NIGHT)

struct badge {
    unsigned short site;
    unsigned char  perms;          /* PERM_* bits */
    unsigned char  zone;
    enum level     level;
    char           role[12];
};

/* Code layout: site in bits 16-31, zone in 12-15, level in 8-11, permissions in 0-7. */
static int decode(unsigned int code, struct badge *b) {
    b->site  = (unsigned short)(code >> 16);
    b->zone  = (code >> 12) & 0xf;
    b->level = (enum level)((code >> 8) & 0xf);
    b->perms = code & 0xff;
    return b->site == SITE_TAG && b->level <= LEVEL_AUDITOR;
}

/* Each level adjusts the permissions written on the badge. */
static void apply_level(struct badge *b) {
    switch (b->level) {
    case LEVEL_VISITOR:
        b->perms &= PERM_DOCK;                 /* visitors keep the dock and nothing else */
        strcpy(b->role, "visitor");
        break;
    case LEVEL_STAFF:
        b->perms |= PERM_DOCK;
        strcpy(b->role, "staff");
        break;
    case LEVEL_SUPERVISOR:
        b->perms |= PERM_DOCK | PERM_COLD;
        strcpy(b->role, "supervisor");
        break;
    case LEVEL_MANAGER:
        b->perms &= ~PERM_TEMP;                /* managers are never temporary */
        strcpy(b->role, "manager");
        break;
    case LEVEL_AUDITOR:
        b->perms ^= PERM_VAULT;                /* auditors swap the vault permission */
        strcpy(b->role, "auditor");
        break;
    }
}

int main(void) {
    char line[32];
    unsigned int code;
    struct badge b;

    printf("Access code (hex): ");
    if (!fgets(line, sizeof line, stdin)) return 1;
    if (sscanf(line, "%x", &code) != 1) return 1;

    memset(&b, 0, sizeof b);
    if (!decode(code, &b)) { puts("Invalid badge."); return 1; }
    apply_level(&b);
    printf("Badge for zone %u, level: %s.\n", b.zone, b.role);

    if (b.perms & PERM_TEMP) { puts("Temporary badges can't open the vault."); return 1; }
    if (!(b.perms & PERM_NIGHT)) { puts("Vault is closed during the day shift."); return 1; }

    if (b.zone == VAULT_ZONE && b.level == LEVEL_AUDITOR && b.perms == VAULT_NEEDS) {
        puts("Vault door open.");
        return 0;
    }
    puts("Access denied.");
    return 1;
}
