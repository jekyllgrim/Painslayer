void main()
{
    FragColor = texture(InputTexture, TexCoord);
    FragColor.r = FragColor.g = FragColor.b = 1.0 - (0.21 * FragColor.r + 0.72 * FragColor.g + 0.07 * FragColor.b);
	FragColor.r *= 1.8;
	FragColor.g *= 1.2;
	FragColor.b *= 0.7;
}