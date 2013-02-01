
chunk = <<script
askdgh sdlkjh asdsdl
sd
dsfsdf-
script

puts chunk.match(/.*(<!-- WRITE_BLOCK_END -->)/m).to_s