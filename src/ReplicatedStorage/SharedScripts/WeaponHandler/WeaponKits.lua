-- Lists the weapon kits and what each kit contains

return {
	Assault = {
		Weapons = {
			Primary = "M4A1";
			Secondary = "M1911A1";
		};
		Equipment = {
			{
				Name = "Frag Grenade";
				Amount = 2;
			};
		};
		layoutOrder = 1;
	};
	Support = {
		Weapons = {
			Primary = "AK47";
			Secondary = "Desert Eagle";
		};
		Equipment = {
			{
				Name = "Flashbang";
				Amount = 2;
			};
		};
		layoutOrder = 2;
	};
	Recon = {
		Weapons = {
			Primary = "Sniper";
			Secondary = "M1911A1";
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