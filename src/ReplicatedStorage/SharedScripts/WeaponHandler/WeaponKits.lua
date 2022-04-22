-- Lists the weapon kits and what each kit contains

return {
	Assault = {
		Weapons = {
			Primary = "M4A1";
			Secondary = "Desert Eagle";
		};
		Equipment = {
			{
				Name = "M62";
				Amount = 2;
			};
		};
		layoutOrder = 1;
	};
	Support = {
		Weapons = {
			Primary = "AK47";
			Secondary = "M1911A1";
		};
		Equipment = {
			{
				Name = "Flare";
				Amount = 2;
			};
		};
		layoutOrder = 2;
	};
	Recon = {
		Weapons = {
			Primary = "Intervention";
			Secondary = "Desert Eagle";
		};
		Equipment = {
			{
				Name = "Smoke Grenade";
				Amount = 2;
			}
		};
		layoutOrder = 3;
	};
}