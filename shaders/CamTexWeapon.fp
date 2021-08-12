void SetupMaterial(inout Material matid)
{
	vec2 texCoord = vTexCoord.xy;
	texCoord.y = 1.0 - texCoord.y;
	vec4 camTexColor = texture(camTex, texCoord);
	matid.Base = camTexColor;
	matid.Bright = texture(brighttexture, texCoord);
}
