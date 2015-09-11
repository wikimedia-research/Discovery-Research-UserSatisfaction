#include <Rcpp.h>
using namespace Rcpp;

std::vector < int > intertime_single(std::vector < int > events){

  if(events.size() == 1){
    std::vector < int > output(1);
    output[0] = -1;
    return output;
  }

  unsigned int input_size = events.size();
  std::vector < int > output(input_size-1);
  std::sort(events.begin(),events.end());

  for(unsigned int i = 1; i < input_size; i++){
    output[i-1] = (events[i] - events[i-1]);
  }

  return output;
}

// [[Rcpp::export]]
std::vector < int > generate_intertimes(std::list < std::vector < int > > events) {

  std::list < std::vector < int > >::const_iterator iterator;
  std::vector < int > output;
  std::vector < int > holding;

  for(iterator = events.begin(); iterator != events.end(); ++iterator) {
    holding = intertime_single(*iterator);
    output.insert(output.end(), holding.begin(), holding.end());
    Rcpp::checkUserInterrupt();
  }

  return output;
}
