module arguments;

fault ProgramArgument {
  NOT_FOUND,
  NO_ARGUMENTS
}

fn int! getIntArgument(String[] args, String argument) {
  String strValue = getStringArgument(args, argument)!;
  return strValue.to_int();
}

fn String! getStringArgument(String[] args, String argument) {
  if(args.len == 0) {
    return ProgramArgument.NO_ARGUMENTS?;
  }

  int argumentFoundIndex = -1;
  String foundString = argument;
  for(int i=0; i < args.len; i++) {
    if(args[i] == argument) {
      argumentFoundIndex = i;
      continue;
    }
    if(i == argumentFoundIndex + 1) {
      foundString = args[i];
    }
  }

  bool argumentFound = false;
  if(foundString != argument) {
    argumentFound = true;
  }

  if(!argumentFound) {
    return ProgramArgument.NOT_FOUND?;
  }

  return foundString;
}
